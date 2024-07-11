### Jenkins Installation on Kubernetes

#### Installation Steps

1. **Follow Documentation**

   For detailed instructions on installing Jenkins on Kubernetes, refer to the official documentation at:
   [Jenkins Kubernetes Documentation](https://jenkins.io/doc/book/installing/kubernetes/)

2. **Quick Installation**

   To quickly deploy a default Jenkins instance, execute the following command:

   ```bash
   kubectl apply -f ./jenkins
   ```

3. **Customizing Jenkins URI**

   To customize the URI of your Jenkins instance, modify the `deployment.yaml` file as follows:
   
   ```yaml
   spec:
     template:
       spec:
         containers:
         - name: jenkins
           env:
           - name: JENKINS_OPTS
             value: "--prefix=/jenkins"
   ```

   Ensure that `livenessProbe` and `readinessProbe` paths in the deployment configuration match the configured URI (`/jenkins` in this example).

4. **Exposing Jenkins with Nginx Ingress**

   Given our Kubernetes cluster is divided into multiple namespaces, use Nginx Ingress to expose services across namespaces. Refer to this guide for detailed setup:
   [Routing Ingress Traffic Across Namespaces](https://tech.aabouzaid.com/2022/08/2-ways-to-route-ingress-traffic-across-namespaces.html)

   Alternatively, use the following manifests to configure Ingress:

   **Master Ingress:**

   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   metadata:
     name: ingress-master
     annotations:
       nginx.org/mergeable-ingress-type: "master"
   spec:
     ingressClassName: nginx
     rules:
     - host: k8sbys3bstn.com
       http:
         paths:
         - path: /
           pathType: Prefix
           backend:
             service:
               name: jenkins-service
               port:
                 number: 8080
   ```

   **Namespace-specific Ingress (e.g., for 'jenkins' namespace):**

   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   metadata:
     name: jenkins-ingress
     annotations:
       nginx.org/mergeable-ingress-type: "minion"
   spec:
     ingressClassName: nginx
     rules:
     - host: k8sbys3bstn.com
       http:
         paths:
         - path: /jenkins
           pathType: Prefix
           backend:
             service:
               name: jenkins-service
               port:
                 number: 8080
   ```

#### Applying Ingress Configurations

Apply the Ingress configurations using the following commands:

```bash
kubectl apply -f ./ingress/ingress-master.yaml
kubectl apply -f ./ingress/ingress-jenkins.yaml
```

These steps will ensure Jenkins is installed and accessible within your Kubernetes environment according to your specified configurations.
