// Pipeline job para frontend
pipelineJob('testjobs/frontend-dev') {
    description('Pipeline Frontend')
    
    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url('https://github.com/LogiqueNoire/cineagilefront.git')
                    }
                    branches('dev')
                }
            }
            scriptPath('jenkinsfile.front')
        }
    }
    
    triggers {
        scm('H/5 * * * *') // revisa cada 5 minutos
    }
}
