import triton_python_backend_utils as pb_utils
import numpy as np

DIM = 768

class TritonPythonModel:
    def initialize(self, args):
        pass

    def execute(self, requests):
        responses = []
        for req in requests:
            bsz = pb_utils.get_input_tensor_by_name(req, "ROI").as_numpy().shape[0]
            v = np.random.normal(0,1,(bsz,DIM)).astype(np.float32)
            responses.append(pb_utils.InferenceResponse(output_tensors=[pb_utils.Tensor("EMBED", v)]))
        return responses
