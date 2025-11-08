import triton_python_backend_utils as pb_utils
import numpy as np

class TritonPythonModel:
    def initialize(self, args):
        pass

    def execute(self, requests):
        responses = []
        for req in requests:
            inp = pb_utils.get_input_tensor_by_name(req, "IMAGE").as_numpy()
            out_tensor = pb_utils.Tensor("IMAGE_OUT", inp.astype(np.uint8))
            responses.append(pb_utils.InferenceResponse(output_tensors=[out_tensor]))
        return responses
