from os import environ
from json import dumps, loads
from urllib3 import PoolManager
from datetime import datetime

def handler(event, context):

    sns_message = loads(event['Records'][0]['Sns']['Message'])

    webhook_url = environ['DISCORD_WEBHOOK']
    
    alarm_name = sns_message.get('AlarmName', 'Unknown')
    new_state = sns_message.get('NewStateValue', 'Unknown')
    reason = sns_message.get('NewStateReason', 'No reason provided')
    timestamp = sns_message.get('StateChangeTime', datetime.now().isoformat())

    trigger = sns_message.get('Trigger', {})
    metric_name = trigger.get('MetricName', 'Unknown')
    threshold = trigger.get('Threshold', 'Unknown')
    instance_id = trigger.get('Dimensions', [{}])[0].get('value', 'Unknown')
    region_name = sns_message.get('Region', 'Unknown')  # Region est à la racine, pas dans Trigger

    # Mapper le nom lisible vers le code région AWS
    region_map = {
        "US East (N. Virginia)": "us-east-1",
        "US East (Ohio)": "us-east-2",
        "US West (N. California)": "us-west-1",
        "US West (Oregon)": "us-west-2",
        "EU (Ireland)": "eu-west-1",
        "EU (London)": "eu-west-2",
        "EU (Paris)": "eu-west-3",
        "EU (Frankfurt)": "eu-central-1",
        "EU (Zurich)": "eu-central-2",
        "EU (Stockholm)": "eu-north-1",
        "EU (Milan)": "eu-south-1",
        "EU (Spain)": "eu-south-2",
        "Asia Pacific (Tokyo)": "ap-northeast-1",
        "Asia Pacific (Seoul)": "ap-northeast-2",
        "Asia Pacific (Singapore)": "ap-southeast-1",
        "Asia Pacific (Sydney)": "ap-southeast-2",
        "Asia Pacific (Mumbai)": "ap-south-1",
        "Canada (Central)": "ca-central-1",
        "South America (São Paulo)": "sa-east-1",
    }
    region = region_map.get(region_name, region_name)
    unit = trigger.get('Unit', '')

    if metric_name == 'CPUUtilization':
        threshold_display = f"{threshold}%"
    elif metric_name in ['NetworkIn', 'NetworkOut']:
        threshold_display = f"{threshold / 1024 / 1024:.2f} MB"
    else:
        threshold_display = f"{threshold} {unit}".strip()

    # Créer le lien vers l'instance EC2 dans la console AWS
    ec2_console_url = f"https://console.aws.amazon.com/ec2/v2/home?region={region}#InstanceDetails:instanceId={instance_id}"

    # Créer le message Discord
    message = {
        "content": "⚠️ 🚨 **Veuillez réagir avec ✅ à ce message quand vous avez pris en compte cette alarme**",
        "embeds": [{
            "title": f"🚨 Alarme AWS CloudWatch: {alarm_name}",
            "description": f"**État:** {new_state}",
            "color": 16711680,
            "fields": [
                {
                    "name": "📊 Métrique",
                    "value": metric_name,
                    "inline": True
                },
                {
                    "name": "🎯 Seuil",
                    "value": threshold_display,
                    "inline": True
                },
                {
                    "name": "💻 Instance",
                    "value": f"[{instance_id}]({ec2_console_url})",
                    "inline": True
                },
                {
                    "name": "📝 Raison",
                    "value": reason,
                    "inline": False
                },
                {
                    "name": "🕐 Heure",
                    "value": timestamp,
                    "inline": False
                }
            ],
            "footer": {
                "text": "AWS CloudWatch Monitoring - Production"
            }
        }]
    }
    
    data = dumps(message).encode('utf-8')

    http = PoolManager()

    try:
        http.request(
            'POST',
            webhook_url,
            body=data,
            headers={'Content-Type': 'application/json'}
        )

        return 'Message envoyé avec succès'
    except Exception as e:
        return f"Erreur lors de l'envoi à Discord: {str(e)}"
