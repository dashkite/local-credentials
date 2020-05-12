import {confidential} from "panda-confidential"
import capability from "@dashkite/cobalt"

Confidential = confidential()
Capability = capability Confidential

export {Confidential, Capability}
