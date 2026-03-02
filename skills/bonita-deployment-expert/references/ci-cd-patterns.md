# CI/CD Patterns for Bonita Projects

## GitHub Actions — Build & Test

```yaml
name: Build and Test
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'
          cache: maven

      - name: Configure Bonita Maven repository
        run: |
          mkdir -p ~/.m2
          cat > ~/.m2/settings.xml << 'EOF'
          <settings>
            <servers>
              <server>
                <id>bonitasoft-releases</id>
                <username>${{ secrets.BONITA_REPO_USER }}</username>
                <password>${{ secrets.BONITA_REPO_PASS }}</password>
              </server>
            </servers>
          </settings>
          EOF

      - name: Build
        run: mvn clean package -DskipTests

      - name: Test
        run: mvn verify

      - name: Upload .bar artifact
        uses: actions/upload-artifact@v4
        with:
          name: bonita-application
          path: app/target/*.bar
```

## GitHub Actions — Deploy to Staging

```yaml
name: Deploy to Staging
on:
  workflow_dispatch:
    inputs:
      version:
        description: 'Version to deploy'
        required: true

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - name: Download artifact
        uses: actions/download-artifact@v4

      - name: Deploy to Bonita
        run: |
          # Login
          TOKEN=$(curl -s -X POST "${{ vars.BONITA_URL }}/loginservice" \
            -d "username=${{ secrets.BONITA_USER }}&password=${{ secrets.BONITA_PASS }}" \
            -c cookies.txt | jq -r '.token')

          # Upload .bar
          curl -X POST "${{ vars.BONITA_URL }}/API/processUpload" \
            -b cookies.txt \
            -F "file=@bonita-application/*.bar"
```

## Jenkins Pipeline

```groovy
pipeline {
    agent any
    tools {
        maven 'Maven-3.9'
        jdk 'JDK-17'
    }
    stages {
        stage('Build') {
            steps {
                configFileProvider([configFile(fileId: 'bonita-maven-settings', variable: 'MAVEN_SETTINGS')]) {
                    sh 'mvn clean package -DskipTests -s $MAVEN_SETTINGS'
                }
            }
        }
        stage('Test') {
            steps {
                configFileProvider([configFile(fileId: 'bonita-maven-settings', variable: 'MAVEN_SETTINGS')]) {
                    sh 'mvn verify -s $MAVEN_SETTINGS'
                }
            }
            post {
                always {
                    junit '**/target/surefire-reports/*.xml'
                    junit '**/target/failsafe-reports/*.xml'
                }
            }
        }
        stage('Archive') {
            steps {
                archiveArtifacts artifacts: 'app/target/*.bar', fingerprint: true
            }
        }
    }
}
```
