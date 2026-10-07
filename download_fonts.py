import urllib.request
import re
import os

font_dir = "assets/fonts"
os.makedirs(font_dir, exist_ok=True)

url = "https://fonts.googleapis.com/css?family=Roboto+Slab:400,700"
req = urllib.request.Request(url)

try:
    css = urllib.request.urlopen(req).read().decode('utf-8')
    links = re.findall(r'url\((.*?)\)', css)
    
    names = ["RobotoSlab-Regular.ttf", "RobotoSlab-Bold.ttf"]
    for i, link in enumerate(links):
        if i < 2:
            print(f"Downloading {names[i]}...")
            font_data = urllib.request.urlopen(link).read()
            with open(os.path.join(font_dir, names[i]), "wb") as f:
                f.write(font_data)
                
    print("Done! Files:", os.listdir(font_dir))
except Exception as e:
    print("Error:", e)
