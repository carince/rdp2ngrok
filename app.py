import ngrok, requests, os, socket, time, asyncio, logging, tkinter, privatebinapi, json
from tkinter import simpledialog
logging.basicConfig(filename="C:/Users/Public/rdp2ngrok/app.log",
                    filemode='a',
                    format='%(asctime)s,%(msecs)d %(name)s %(levelname)s %(message)s',
                    datefmt='%H:%M:%S',
                    level=logging.INFO)
logging.info("Running rdp2ngrok")
logger = logging.getLogger('rdp2ngrok')

config = None

# Checks
async def config():
    if os.path.isfile("C:/Users/Public/rdp2ngrok/config.json"):
        logger.info("Found config, importing.")
        with open('C:/Users/Public/rdp2ngrok/config.json', 'r') as openfile:
            config = json.loads(openfile.read())
    else:
        logger.info("No config found, asking user for password.")
        userPass = simpledialog.askstring(title="rdp2ngrok", prompt="Password")

        logger.info("Decrypting...")
        response = privatebinapi.get(
            "https://privatebin.net/?8b582a918856a4ae#DhwfPPEwAQLkCBP5tDJna6xQFwtDAat8EZJmB4PhidFi",
            password=userPass
        )
        config = json.loads(response["text"])
        
        logger.info("Decrypted, dumping to config file.")
        with open("C:/Users/Public/rdp2ngrok/config.json", "w") as outfile:
            outfile.write(json.dumps(config, indent=4))

# Ngrok
async def start_ngrok():
    logger.info(f"config: \n{config}")
    logger.info("Starting ngrok...")
    listener = await ngrok.connect(3389, "tcp", authtoken=config("NGROK_AUTHTOKEN"))
    return listener

# Webhook 
async def send_webhook(url):
    logger.info(f"Sending webhook: \nUser: {os.getlogin()} \nHostname: {socket.gethostname()} \nIngress: {url}")
    data = {
    "content": f"User `{os.getlogin()}` has logged in at computer `{socket.gethostname()}` \nPort 3389 opened at ingress: `{url}`",
    "embeds": None,
    "attachments": []
    }
    result = requests.post(config("WEBHOOK"), json = data)
    try:
        result.raise_for_status()   
    except requests.exceptions.HTTPError as err: logging.error(err)
    else: logger.info(f"Sent webhook payload successfully. Code: {result.status_code}")

async def main():
    await config()
    listener = await start_ngrok()
    await send_webhook(listener.url())
    while (await ngrok.get_listeners()):
        time.sleep(60)
    logger.info("ngrok stopped unexpectedly, running again...")

asyncio.run(main())