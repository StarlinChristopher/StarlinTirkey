const platformButtons = document.querySelectorAll('.platform-option');
let platform = 'App Runner';
for (const button of platformButtons) {
  button.addEventListener('click', () => {
    platform = button.dataset.platform;
    platformButtons.forEach((item) => item.classList.toggle('selected', item === button));
    document.querySelector('#guided-continue').innerHTML = `Configure ${platform} <span>→</span>`;
  });
}

const dialog = document.querySelector('#notice-dialog');
const title = document.querySelector('#dialog-title');
const copy = document.querySelector('#dialog-copy');
const command = document.querySelector('#dialog-command');
function showDialog(heading, text, snippet = '') {
  title.textContent = heading;
  copy.textContent = text;
  command.textContent = snippet;
  dialog.showModal();
}
document.querySelector('#guided-continue').addEventListener('click', () => {
  showDialog(
    `${platform} guided setup`,
    `This starter will generate a reviewable Terraform plan for ${platform}. Add your application source and AWS account details before applying. No cloud resources are changed by this dashboard.`,
    platform === 'App Runner'
      ? 'cd terraform/guided\ncp terraform.tfvars.example terraform.tfvars\nterraform init && terraform validate && terraform plan'
      : `${platform} is a planned Guided template; no infrastructure is created by this selection yet.`,
  );
});
for (const button of document.querySelectorAll('.env-link')) {
  button.addEventListener('click', () => {
    const env = button.dataset.env;
    showDialog(
      `${env[0].toUpperCase()}${env.slice(1)} environment`,
      `Use the isolated aws-${env} profile and Terraform environment. Configure an IAM role ARN in ~/.aws/config before using cloud commands.`,
      `AWS_PROFILE=aws-${env} terraform -chdir=terraform/eks/environments/${env} init\nAWS_PROFILE=aws-${env} terraform -chdir=terraform/eks/environments/${env} plan`,
    );
  });
}
document.querySelector('#profile-help').addEventListener('click', () => {
  showDialog(
    'Environment profiles',
    'The project can create role-based aws-dev, aws-staging and aws-prod profiles. Set AWS_DEV_ROLE_ARN, AWS_STAGING_ROLE_ARN and AWS_PROD_ROLE_ARN from your account administrator before generating ~/.aws/config entries.',
    './scripts/configure-aws-profiles.sh',
  );
});
document.querySelector('.dialog-close').addEventListener('click', () => dialog.close());
document.querySelector('.dialog-ok').addEventListener('click', () => dialog.close());
const envSelect = document.querySelector('#env-select');
function syncEnv() {
  const env = envSelect.value;
  document.querySelector('#cluster-command').textContent = `aws-devops-${env}`;
  document.querySelector('#profile-command').textContent = `aws-${env}`;
}
envSelect.addEventListener('change', syncEnv);
for (const tab of document.querySelectorAll('.local-tab')) {
  tab.addEventListener('click', () => {
    document.querySelectorAll('.local-tab').forEach((item) => item.classList.toggle('active', item === tab));
    document.querySelector('#local-command').innerHTML = tab.dataset.local === 'k3d'
      ? '$ ./scripts/local-up.sh dev<br />$ kubectl config use-context k3d-aws-devops-dev<br />$ kubectl apply -k k8s/dev'
      : '$ docker compose up --build --pull always<br />$ curl http://127.0.0.1:8080/health<br />$ docker compose down';
  });
}
