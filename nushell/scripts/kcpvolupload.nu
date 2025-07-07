#!/usr/bin/env nu
def main [--deployment (-d): string, --volume (-v): string, --path (-p): path, --namespace (-n): string, --files, --wait (-w): duration = 2sec, --wait-times: int = 10] {
  print $"Moving ($path) to the volume ($volume) from the deployment ($deployment)"
  mut $deployment_object = {}
  if ($namespace != null) {
    $deployment_object = (kubectl get deployment -n $namespace -o yaml $deployment | from yaml)
    if ($deployment_object | is-empty) {
      error make {msg: $"Deployment ($deployment) not found in the namespace ($namespace)", label: {text: "couldn't find this deployment", span: (metadata $deployment).span}, help: "Check the name of the deployment and if the namespace is right"}
    }
  } else {
    $deployment_object = (kubectl get deployment -o yaml $deployment | from yaml)
    if ($deployment_object | is-empty) {
      error make {msg: $"Deployment ($deployment) not found in the current namespace", label: {text: "couldn't find this deployment", span: (metadata $deployment).span}, help: "Check the name of the deployment and if the namespace is right"}
    }
  }
  let $dobj = $deployment_object
  print "searching for the volume in the deployment object"
  let $volume_information = ($deployment_object | get spec.template.spec.volumes | where name == $volume)

  if ($volume_information | is-empty) {
    error make {msg: $"Volume ($volume) was not found in the deployment ($deployment)", label: {text: "this volume was not found in the given deployment", span: (metadata $volume).span}, help: "Check the name of the volumes in the deployment"}
  }

  let $volume_pvc_name = $volume_information.0.persistentVolumeClaim.claimName

  let temp_pod = $"
apiVersion: v1
kind: Pod
metadata:
  name: nuguish-volupload-($deployment)
spec:
  containers:
  - image: nginx
    name: nginx
    volumeMounts:
    - mountPath: /data
      name: volume
  volumes:
  - name: volume
    persistentVolumeClaim:
      claimName: ($volume_pvc_name)
  "
  print $"scaling down the deployment ($deployment)"
  kubectl scale deployment $deployment --replicas 0
  print $"creating new temporary pod for moving data: nuguish-volupload-($deployment)"
  $temp_pod | kubectl apply -f -
  print $"waiting for pod to be running..."
  mut $not_running = (kubectl get pod $"nuguish-volupload-($deployment)" -o yaml | from yaml | get status.phase) != "Running"
  mut $counter = 0
  let $limit = $wait_times
  mut $error = false
  while $not_running {
    sleep $wait
    $counter += 1
    $not_running = (kubectl get pod $"nuguish-volupload-($deployment)" -o yaml | from yaml | get status.phase) != "Running"
    if ($counter >= $limit) {
      $error = true
      break
    }
  }
  if ($error) {
    print $"There was an error while trying to get the temporary pod running, reverting everything back..."
    cleanup $deployment_object $namespace
    error make {msg: "There was an issue while trying to create the temporary pod. Please verify your kubernetes events", help: "You can view your kuberentes events by running 'kubectl get events'"}
  }

  print $"Moving data from ($path) to the created temp container..."
  try {
    if ($files) {
      ls $path | each {|ea|
        print $"Copying ($ea.name)"
        kubectl cp $ea.name $"nuguish-volupload-($deployment):/data"
      }
    } else {
      kubectl cp $path $"nuguish-volupload-($deployment):/data"
    }
  } catch {|err|
    cleanup $dobj $namespace
    error make {msg: "There was an error while copying the files over.", }
  }

  print "Everything completed! Reverting things to normal"
  cleanup $deployment_object $namespace
}


def cleanup [deployment_object: record, namespace?: string] {
  let $deployment = ($deployment_object | get metadata.name)
  if ($namespace != null) {
    kubectl scale deployment  -n $namespace --replicas ($deployment_object | get spec.replicas)
    kubectl delete pod -n $namespace $"nuguish-volupload-($deployment)"
  } else {
    kubectl scale deployment $deployment --replicas ($deployment_object | get spec.replicas)
    kubectl delete pod $"nuguish-volupload-($deployment)"
  }
}
