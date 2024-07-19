# Installation Guide for Strimzi

This guide will walk you through the installation of Strimzi, a Kafka operator for Kubernetes. We will create a namespace for Kafka, install Strimzi, and configure persistent local storage on worker nodes.

## Prerequisites

- A running Kubernetes cluster
- kubectl configured to interact with your Kubernetes cluster

## Steps

### 1. Create Kafka Namespace

Create a new namespace for Kafka:
```bash
kubectl create namespace kafka
```

### 2. Install Strimzi

Install the latest version of Strimzi in the `kafka` namespace:
```bash
kubectl create -f 'https://strimzi.io/install/latest?namespace=kafka' -n kafka
```

### 3. Prepare Worker Node for Persistent Storage

On each worker node where Kafka will be running, execute the following commands to set up the directory for Kafka storage:
```bash
sudo mkdir -p /kafka
sudo chmod -R 775 /kafka
```

### 4. Apply Persistent Volume Configuration

Apply the Persistent Volume (PV) and Persistent Volume Claim (PVC) configuration. Ensure you have the `volume-kafka.yaml` file properly configured. Apply it using:
```bash
kubectl apply -f volume-kafka.yaml
```

### 5. Deploy Kafka Cluster

Deploy a single-node Kafka cluster using a custom manifest to define the security context for the PV. This ensures the proper permissions for Kafka. Ensure your `kafka-single-node.yaml` includes the following configuration:

```yaml
spec:
  kafka:
    template:
      pod:
        securityContext:
          fsGroup: 1000
          runAsUser: 1000
```

Apply the configuration using:
```bash
kubectl apply -f kafka-single-node.yaml
```

## Additional Configuration Options

You can refer to the official [Strimzi documentation](https://strimzi.io/docs/) for more detailed instructions and additional configuration options.

### Storage Options

If you prefer to use ephemeral storage instead of persistent storage, you can configure Strimzi accordingly. Alternatively, you can use a persistent volume provider that is supported by your Kubernetes cluster.

#### Example: Defining Storage Class and Persistent Volume

1. **Storage Class:** Define a storage class if you are using a persistent volume provider.
2. **Persistent Volume (PV):** Configure and apply a PV specification.

For more details on how to define these resources, please refer to the [Kubernetes documentation on Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/).

---

By following these steps, you should be able to successfully install and configure Strimzi with persistent local storage on your Kubernetes cluster.
