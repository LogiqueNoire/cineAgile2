// Crear carpetas
['frontend', 'backend', 'iac'].each { f ->
    folder(f) {
        description("Carpeta ${f} creada por seed job")
    }
}

// FRONTEND - PIPELINE
pipelineJob('frontend/dev') {
    description("Pipeline del Frontend - Dev")
    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url("https://github.com/logiquenoire/cineagile2.git")
                    }
                    branch("main")
                }
            }
            scriptPath("jobs/frontend/Jenkinsfile")
        }
    }
}

// BACKEND - PIPELINE
pipelineJob('backend/dev') {
    description("Pipeline del Backend - Dev")
    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url("https://github.com/logiquenoire/cineagile2.git")
                    }
                    branch("main")
                }
            }
            scriptPath("jobs/backend/Jenkinsfile")
        }
    }
}

// IAC - PIPELINE
// pipelineJob('iac/dev') {
//     description("Pipeline de Infraestructura - Terraform / Ansible")
//     definition {
//         cpsScm {
//             scm {
//                 git {
//                     remote {
//                         url("https://github.com/logiquenoire/cineagile2.git")
//                     }
//                     branch("main")
//                 }
//             }
//             scriptPath("iac/Jenkinsfile")
//         }
//     }
// }