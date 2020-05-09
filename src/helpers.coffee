import {confidential} from "panda-confidential"
import capability from "panda-capability"

Confidential = confidential()
Capability = capability Confidential

export {Confidential, Capability}
