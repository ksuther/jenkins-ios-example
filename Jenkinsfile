#!groovy

// This Jenkinsfile is used to build, test, and generate code coverage for an iOS project
// If you want to use this Jenkinsfile with your own project you'll need to make some changes:
// 1. Change the following variables to match your project
def xcodeproj = 'Jenkins iOS Example.xcodeproj' // Path to the xcodeproj
def xcarchive_name = "Jenkins iOS Example.xcarchive" // Name of the archive to build
def build_scheme = 'Jenkins iOS Example' // Scheme to build the app
def test_scheme = 'Jenkins iOS Example' // Scheme to build tests
def simulator_device = 'iPhone 7' // Name of the device type to use for tests
// 2. If you want to upload builds to a server, update the buildURL variable and uncomment the scp command under stage('Save')
// 3. If you want Slack notifications, return true in the functions below and set the Slack channel
def slackChannel = '#general'

@Library('shared') _

def sendStartNotification() {
    // Send a Slack notification when the build starts?
    false
}

def sendSuccessNotification() {
    // Send a Slack notification when the build succeeds?
    false
}

def sendUnstableNotification() {
    // Send a Slack notification when the build is unstable (such as when tests fail)?
    false
}

def sendFailNotification() {
    // Send a Slack notification when the build fails (such as build failures)?
    false
}

def slackMessagePrefix() {
    // Generate a nicer name for branches in Slack notifications
    // Converts Job Name/feature%2Fnew-feature to Job Name - feature/new-feature
    def jobName = env.JOB_NAME.replaceAll("/", " - ").replaceAll("%2F", "/")

    "${jobName} - #${env.BUILD_NUMBER}"
}

// Configure Jenkins to keep the last 200 build results and the last 50 build artifacts for this job
properties([buildDiscarder(logRotator(artifactNumToKeepStr: '50', numToKeepStr: '200'))])

node {
    def startTime = System.currentTimeMillis()
    def buildURL = "https://example.com/builds/ios"
    def branchNameForURL = env.BRANCH_NAME.replaceAll("/", "-")

    try {
        stage('Check project') {
            if (sendStartNotification()) {
                slackSend channel: slackChannel, color: colorForBuildResult(currentBuild.getPreviousBuild()), message: slackMessagePrefix() + " Started (<${env.BUILD_URL}|Open>)"
            }

            checkout scm
            
            // Delete and recreate build directory
            dir('build') {
                deleteDir()
            }

            sh "mkdir -p build"
        }

        stage('Build') {
            wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'XTerm']) {
                // Just build for the example project
                // We can't archive because there's no code signing set up
                // Set up a development team and code signing to archive an ipa
                sh "xcrun xcodebuild -scheme '${build_scheme}' -destination 'name=iPhone 7' clean build | tee build/xcodebuild.log | xcpretty"

                // Uncomment this when building a project with code signing set up
                /*sh "xcrun xcodebuild -scheme '${build_scheme}' archive -archivePath 'build/${xcarchive_name}' | tee build/xcodebuild.log | xcpretty"
                sh "xcrun xcodebuild -exportArchive -exportOptionsPlist exportOptions.plist -archivePath 'build/${xcarchive_name}' -exportPath build"

                dir('build') {
                    sh "zip -qr 'Jenkins-iOS-Example-${env.BUILD_NUMBER}.zip' '${xcarchive_name}'"
                    sh "mv 'Jenkins iOS Example.ipa' 'Jenkins iOS Example-${branchNameForURL}.ipa'"
                }*/
            }
        }

        stage('Test') {
            wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'XTerm']) {

                if (sh(script: "which bluepill || true", returnStdout: true).trim().length() > 0) {
                    // bluepill is installed
                    // Perform incremental builds to speed up builds a bit (use clean build-for-testing if you need a clean build every time)
                    sh "xcodebuild -scheme '${test_scheme}' -enableCodeCoverage YES -configuration Debug -destination 'name=${simulator_device}' build-for-testing | tee build/xcodebuild-test.log | xcpretty"

                    // Determine the location of the apps
                    app_path = sh(script: "xcodebuild -scheme '${test_scheme}' -configuration Debug -sdk iphonesimulator -destination 'name=${simulator_device}' build -showBuildSettings CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO 2>/dev/null | grep CODESIGNING_FOLDER_PATH | awk -F' = ' '{ gsub(\"Build/Products\", \"Build/Intermediates/CodeCoverage/Products\", \$2); print \$2 }'", returnStdout: true).trim()

                    // Determine the location of CodeCoverage for each app so we can manually generate Coverage.profdata after the tests run
                    coverage_path = sh(script: "dirname \$(dirname \$(dirname '${app_path}'))", returnStdout: true).trim()

                    // Execute bluepill in parallel to test multiple schemes at once
                    parallel (
                        "Unit Tests": {
                            sh "bluepill -a '${app_path}' -s '${xcodeproj}/xcshareddata/xcschemes/Jenkins iOS ExampleTests.xcscheme' -o build/reports-tests -S 180 -T 450 -n 1 || true"
                        },
                        "UI Tests": {
                            sh "bluepill -a '${app_path}' -s '${xcodeproj}/xcshareddata/xcschemes/Jenkins iOS ExampleUITests.xcscheme' -o build/reports-uitests -S 180 -T 450 -n 1 || true"
                        }
                    )

                    // Copy JUnit output into place
                    sh "mkdir -p build/reports"
                    sh "cp build/reports-tests/TEST-FinalReport.xml build/reports/tests.xml"
                    sh "cp build/reports-uitests/TEST-FinalReport.xml build/reports/uitests.xml"

                    // Generate coverage
                    // Manually merge profraw into a single profdata file and put it where CodeCoverage.profdata normally goes
                    sh "xcrun llvm-profdata merge -sparse build/reports-tests/**/*.profraw build/reports-uitests/**/*.profraw -o '${coverage_path}/Coverage.profdata'"
                    sh "slather coverage --scheme '${test_scheme}' --cobertura-xml --output-directory build/coverage '${xcodeproj}'"
                } else {
                    // bluepill isn't installed, use xcodebuild to perform tests

                    // Quit the iOS Simulator and reset all simulators so we're always starting with a clean slate
                    sh "killall 'Simulator' 2&> /dev/null || true"
                    sh "xcrun simctl erase all"

                    // Run tests and generate coverage
                    sh "xcodebuild -scheme '${test_scheme}' -enableCodeCoverage YES -configuration Debug -destination 'name=${simulator_device}' test | tee build/xcodebuild-test.log | xcpretty -r junit --output build/reports/junit.xml"
                    sh "slather coverage --scheme '${test_scheme}' --cobertura-xml --output-directory build/coverage '${xcodeproj}'"

                    // If you have multiple schemes you can run them sequentially here
                    // For example, you might have a separate iPad app
                    //sh "mv build/coverage/cobertura.xml build/coverage/iphone.xml"
                    //sh "xcodebuild -scheme 'Jenkins iOS Example iPad' -enableCodeCoverage YES -configuration Debug -destination 'name=iPad Air 2' test | tee build/xcodebuild-ipad-test.log | xcpretty -r junit --output build/reports/junit-ipad.xml"
                    //sh "slather coverage --scheme 'Jenkins iOS Example iPad' --cobertura-xml --output-directory build/coverage '${xcodeproj}'"
                    //sh "mv build/coverage/cobertura.xml build/coverage/ipad.xml"
                }
            }

            step([$class: 'JUnitResultArchiver', testResults: 'build/reports/*.xml'])
            step([$class: 'CoberturaPublisher', autoUpdateHealth: false, autoUpdateStability: false, coberturaReportFile: 'build/coverage/*.xml', failNoReports: true, failUnhealthy: false, failUnstable: false, maxNumberOfBuilds: 0, onlyStable: false, sourceEncoding: 'UTF_8', zoomCoverageChart: true])
        }

        stage('Save') {
            dir('build') {
                // Uncomment this when 
                // archiveArtifacts artifacts: '*.ipa', fingerprint: true

                // You can archive other files as well
                // For example, you might have images of build failures from UI tests or KIF
                // archiveArtifacts artifacts: '*.ipa, UITests/*.png, KIF/*.png', fingerprint: true

                // Uncomment below if you want to upload the resulting ipa somewhere
                // You need to add an SSH key in the Credentials section of Jenkins
                /*sshagent(['build-results-server']) {
                    sh 'scp *.ipa jenkins@example.com:~/builds/ios'
                }*/
            }

            def endTime = System.currentTimeMillis()
            def durationString = createDurationString(startTime, endTime)
            def testResults = getTestResult()
            def testResultString = getTestResultString()
            def unstableFromTests = testResults && (testResults[1] > 0 || testResults[2] > 0)

            if (sendSuccessNotification() || (unstableFromTests && sendUnstableNotification())) {
                def status = unstableFromTests ? 'Unstable' : 'Success'
                def color = unstableFromTests ? 'warning' : 'good'
                def message = slackMessagePrefix() + " ${status} after ${durationString} (<${env.BUILD_URL}|Open>)\n\t${testResultString}"

                if (buildURL) {
                    message = message + "\n" + buildURL
                }

                slackSend channel: slackChannel, color: color, message: message
            }
        }
    } catch (e) {
        def endTime = System.currentTimeMillis()
        def durationString = createDurationString(startTime, endTime)
        def testResultString = getTestResultString()

        if (sendFailNotification()) {
            slackSend channel: slackChannel, color: 'danger', message: slackMessagePrefix() + " Failed after ${durationString} (<${env.BUILD_URL}|Open>)\n\t${testResultString}"
        }

        throw e
    }
}

def createDurationString(startTime, endTime) {
    def duration = endTime - startTime
    def minutes = (int)(duration / 60000)
    def seconds = (int)(duration / 1000) % 60

    /${minutes} min ${seconds} sec/
}

def colorForBuildResult(build) {
    if (build == null || build.result == 'SUCCESS') {
        'good'
    } else if (build.result == 'UNSTABLE') {
        'warning'
    } else {
        'danger'
    }
}
