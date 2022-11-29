sed -ie 's/127.0.0.1/0.0.0.0/g' /etc/hosts
apt-get -y install \
      ca-certificates \
      curl \
      gnupg \
      lsb-release

mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg |  gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" |  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update && \
   apt-get -y install \
   docker-ce \
   docker-ce-cli \
   containerd.io \
   docker-compose-plugin \
   python3-pip \
   python3-dev

usermod -aG docker vagrant

curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.17.0/kind-linux-amd64
chmod +x ./kind
mv ./kind /usr/local/bin
su - vagrant -c "kind create cluster --name kubeflow-cluster"

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

mkdir -p /opt/hacks
chown vagrant. /opt/hacks 

su - vagrant<<'EOF'
export PATH=$PATH:$HOME/.local/bin
export PIPELINE_VERSION=1.8.5
kubectl apply -k "github.com/kubeflow/pipelines/manifests/kustomize/cluster-scoped-resources?ref=$PIPELINE_VERSION"
kubectl wait --for=condition=established --timeout=60s crd/applications.app.k8s.io
kubectl apply -k "github.com/kubeflow/pipelines/manifests/kustomize/env/platform-agnostic-pns?ref=$PIPELINE_VERSION"

pip3 install --upgrade pip
pip3 install virtualenv
pip3 install jupyter

cd /opt/hacks/
virtualenv kubeflow
source kubeflow/bin/activate

jupyter notebook &
kubectl wait --timeout=600s --for=condition=ready pod -n kubeflow --all
kubectl port-forward -n kubeflow svc/ml-pipeline-ui 8080:80 --address 0.0.0.0 &

EOF
