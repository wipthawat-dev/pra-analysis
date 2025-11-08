import triton_python_backend_utils as pb_utils
import numpy as np

class TritonPythonModel:
    def initialize(self, args):
        pass

    def execute(self, requests):
        responses = []
        for req in requests:
            emb = pb_utils.get_input_tensor_by_name(req, "EMBED").as_numpy()
            bsz = emb.shape[0]
            logits = np.stack([np.full((bsz,),0.4), np.full((bsz,),0.6)], axis=1).astype(np.float32)
            responses.append(pb_utils.InferenceResponse(output_tensors=[pb_utils.Tensor("LOGITS", logits)]))
        return responses
