#!groovy
@Library('Infrastructure') _
import uk.gov.hmcts.contino.Testing
import uk.gov.hmcts.contino.Tagging

GITHUB_PROTOCOL = "https"
GITHUB_REPO = "github.com/contino/moj-module-waf/"

properties(
    [[$class: 'GithubProjectProperty', projectUrlStr: 'https://www.github.com/contino/moj-module-waf/'],
     pipelineTriggers([[$class: 'GitHubPushTrigger']])]
)

try {
  node {
    platformSetup {

      stage('Checkout') {
        deleteDir()
        checkout scm
      }

      terraform.ini(this)
      stage('Terraform Linting Checks') {
        terraform.lint()
      }

      testLib = new Testing(this)
      stage('Terraform Unit Testing') {
        testLib.unitTest()
      }

      /*Commeting for now as failing after 10m of building the fixture
        something makes terraform receive a cancel signal that triggers kitchen to fail reaching
        the message:
        https://github.com/hashicorp/terraform/issues/13851#issuecomment-297203239
      stage('Terraform Integration Testing') {
        testLib.moduleIntegrationTests()
      }*/

      stage('Tagging') {
        def tag = new Tagging(this)
        printf tag.applyTag(tag.nextTag())
      }
    }
  }
}
catch (err) {
  throw err
}