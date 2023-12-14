#!/bin/bash

if [[ -z "${MODEL_DEPLOYMENT_OCID}" ]]; then
  auth_method=instance_principal
else
  auth_method=resource_principal
fi

if [ -n "\$BUCKET" ]; then
  echo "BUCKET variable are set."
  #oci os object sync --auth resource_principal --bucket-name genai --dest-dir /home/datascience/llma2/
  /root/bin/oci os object sync --auth $auth_method --bucket-name $BUCKET --dest-dir /home/datascience/model/
  MODEL="/home/datascience/model/$MODEL"  
elif [ -n "\$TOKEN_FILE" ]; then
  export HUGGING_FACE_HUB_TOKEN=$(cat $TOKEN_FILE)
  echo "The md5 of token is $(md5sum $TOKEN_FILE)"
  mkdir -p /home/datascience/.cache/huggingface
  cp $TOKEN_FILE /home/datascience/.cache/huggingface/token
  echo "Copied token file to /home/datascience/.cache/huggingface, $(md5sum /home/datascience/.cache/huggingface/token)"
  echo "Set HuggingFace cache folder..."
  export HUGGINGFACE_HUB_CACHE=/home/datascience/.cache
  echo "The size of partitions"
  echo $(df -h /home/datascience)
  df -h
  echo "Checking internet connection: "
  curl -s --connect-timeout 15 http://example.com > /dev/null && echo "Connected" || echo "Not connected"
  echo $(du -sh /home/datascience/*)
else
  echo "No bucket or authentication token is provided. Weights are assumed to be downloaded from OCI Model Catalog."
fi

echo "Starting vllm engine..."
source activate vllm
WEB_CONCURRENCY=1 python $VLLM_DIR/vllm-api-server.py --port ${PORT} --host 0.0.0.0 --log-config $VLLM_DIR/vllm-log-config.yaml --model ${MODEL} --tensor-parallel-size ${TENSOR_PARALLELISM}


echo "Exiting vLLM. Here is the disk utilization of /home/datascience - "
echo $(du -sh /home/datascience)
echo "server logs: "
ls -lah /home/datascience
cat /home/datascience/server.log
