import triton_python_backend_utils as pb_utils
import numpy as np

class TritonPythonModel:
    def initialize(self, args):
        pass

    def execute(self, requests):
        responses = []
        for req in requests:
            bsz = pb_utils.get_input_tensor_by_name(req, "IMAGE").as_numpy().shape[0]
            boxes = np.array([[[50,50,200,200,0.9]]]*bsz, dtype=np.float32)
            responses.append(pb_utils.InferenceResponse(output_tensors=[pb_utils.Tensor("BBOX", boxes)]))
        return responses
