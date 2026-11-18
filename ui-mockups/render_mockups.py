from PIL import Image, ImageDraw, ImageFont, ImageFilter
import random, math
W,H=1280,720; random.seed(7)
F="/usr/share/fonts/truetype/sand-box/google/"
brush=lambda s: ImageFont.truetype(F+"Nanum Brush Script/NanumBrushScript-Regular.ttf",s)
pix=lambda s: ImageFont.truetype(F+"Pixelify Sans/PixelifySans-VariableFont_wght.ttf",s)
INK=(14,12,18); PAPER=(226,214,190); RED=(178,34,38)
def ridge(d,base,amp,col,seed,rough=0.5):
    random.seed(seed); pts=[]; y=base
    for x in range(0,W+20,8):
        y+=random.uniform(-amp,amp)*rough; y=min(max(y,base-amp*3),base+amp); pts.append((x,y))
    d.polygon(pts+[(W,H),(0,H)],fill=col)
def bg(scene=0):
    im=Image.new("RGB",(W,H)); d=ImageDraw.Draw(im)
    for y in range(H):
        t=y/H; d.line([(0,y),(W,y)],fill=(int(150-100*t),int(196-120*t),int(186-110*t)))
    # moon with craters
    mx,my=(930,190) if scene==0 else (300,150)
    d.ellipse([mx-110,my-110,mx+110,my+110],fill=(240,238,222))
    random.seed(3)
    for _ in range(14):
        r=random.randint(6,22); a=random.uniform(0,6.28); q=random.uniform(0,80)
        x,y=mx+q*math.cos(a),my+q*math.sin(a); d.ellipse([x-r,y-r,x+r,y+r],fill=(222,222,206))
    # thin clouds
    for i in range(5):
        y=random.randint(120,330); x=random.randint(-100,W)
        d.rounded_rectangle([x,y,x+random.randint(200,420),y+6],3,fill=(190,220,210))
    ridge(d,420,40,(92,140,134),1); ridge(d,480,30,(56,98,96),2)
    # pagoda
    px=200 if scene==0 else 1000
    for i,w in enumerate([150,120,92,66]):
        yy=400-i*48; d.polygon([(px-w,yy),(px+w,yy),(px+w*0.7,yy-22),(px-w*0.7,yy-22)],fill=(34,60,60))
        d.rectangle([px-w*0.5,yy,px+w*0.5,yy+26],fill=(34,60,60))
        d.rectangle([px-10,yy+6,px+10,yy+20],fill=(200,120,60))
    d.line([(px,208),(px,170)],fill=(34,60,60),width=4)
    ridge(d,560,26,(24,44,46),5)
    # bamboo foreground
    for x in [40,70,1220,1245]:
        d.rectangle([x,0,x+12,H],fill=INK)
        for y in range(40,H,90): d.line([(x-2,y),(x+14,y)],fill=(40,36,46),width=3)
        for y in range(80,H,140): d.polygon([(x+12,y),(x+70,y+18),(x+12,y+12)],fill=INK)
    fog=Image.new('RGBA',(W,H),(0,0,0,0)); fd=ImageDraw.Draw(fog)
    for i in range(6): fd.rectangle([0,430+i*22,W,452+i*22],fill=(170,210,200,22))
    fog=fog.filter(ImageFilter.GaussianBlur(14)); im.paste(fog,(0,0),fog)
    # grain
    n=Image.effect_noise((W,H),18).convert("RGB"); im=Image.blend(im,n,0.06)
    return im
def ninja(d,x,y,s=1,face=1):
    c=INK; f=face
    P=lambda pts:[(x+px*s*f,y+py*s) for px,py in pts]
    # scarf
    d.line(P([(-4,-50),(-30,-46),(-52,-54),(-70,-44)]),fill=RED,width=int(5*s),joint="curve")
    d.polygon(P([(-10,-44),(10,-44),(14,-22),(18,-6),(6,-4),(0,-14),(-8,-4),(-20,-6),(-14,-24)]),fill=c) # torso+hips
    d.polygon(P([(-8,-4),(-2,-4),(-10,16),(-26,30),(-30,26),(-18,12)]),fill=c) # back leg
    d.polygon(P([(6,-4),(18,-6),(26,14),(30,30),(22,30),(16,14)]),fill=c) # front leg
    d.ellipse(P([(-9,-64),(11,-44)]) if f>0 else [x-11*s,y-64*s,x+9*s,y-44*s],fill=c) # head
    d.line(P([(-2,-55),(10,-55)]),fill=(230,225,205),width=max(2,int(2.5*s))) # eye slit
    d.line(P([(10,-38),(26,-26)]),fill=c,width=int(5*s)) # arm
    d.line(P([(24,-24),(62,-70)]),fill=(205,215,210),width=max(2,int(2.4*s))) # blade
    d.line(P([(20,-20),(26,-27)]),fill=c,width=int(5*s))
def grass(d,x0,x1,y):
    random.seed(x0)
    for x in range(x0,x1,5): d.polygon([(x,y+2),(x+random.randint(1,4),y-random.randint(3,14)),(x+5,y+2)],fill=INK)
def btn(d,x,y,w,h,txt,sel=False):
    if sel: d.polygon([(x-14,y+h/2),(x-4,y+h/2-8),(x-4,y+h/2+8)],fill=RED)
    d.text((x+8,y+h/2),txt,font=pix(34),fill=PAPER if sel else (150,140,130),anchor="lm")
    if sel: d.line([(x+8,y+h-2),(x+8+d.textlength(txt,font=pix(34)),y+h-2)],fill=RED,width=3)
def stroke(d,x0,y0,x1,col=RED):
    random.seed(x0)
    for i in range(18): 
        yy=y0+i*3; d.line([(x0+random.randint(0,30),yy),(x1-random.randint(0,40),yy)],fill=col,width=3)
# main menu
im=bg(0); d=ImageDraw.Draw(im)
stroke(d,90,140,640)
d.text((110,120),"Shadow Ninja",font=brush(150),fill=PAPER)
d.text((118,250),"影 の 忍",font=pix(22),fill=(150,140,130)) if False else d.text((118,262),"— a tale of the last clan —",font=pix(22),fill=(170,160,145))
pn=Image.new('RGBA',(W,H),(0,0,0,0)); pd=ImageDraw.Draw(pn); pd.rectangle([60,300,470,640],fill=(8,14,16,200)); pn=pn.filter(ImageFilter.GaussianBlur(18)); im.paste(pn,(0,0),pn); d=ImageDraw.Draw(im)
for i,t in enumerate(["Continue","New Game","Level Select","Settings","Quit"]): btn(d,120,340+i*60,300,50,t,i==0)
d.rectangle([480,640,W,H],fill=INK); d.polygon([(700,640),(760,520),(1000,505),(1060,640)],fill=INK); grass(d,480,W,640); grass(d,760,1000,512); ninja(d,860,505,2.4,-1)
d.text((W-30,H-24),"v1.0.0",font=pix(16),fill=(110,100,95),anchor="rm")
im.save("ui-mockups/main_menu.png")
# level select
im=bg(1); d=ImageDraw.Draw(im)
ov=Image.new("RGBA",(W,H),(6,16,18,165)); im.paste(ov,(0,0),ov); d=ImageDraw.Draw(im)
stroke(d,70,92,520); d.text((80,50),"Choose your path",font=brush(90),fill=PAPER)
names=["Bamboo Gate","Moon Temple","Ash Village","Iron Fort","Storm Peak","Shogun's Keep"]
pts=[(170,520),(360,400),(560,470),(760,350),(960,430),(1120,300)]
for a,b in zip(pts,pts[1:]):
    for k in range(0,20,2):
        t=k/20; u=(k+1)/20; d.line([(a[0]+(b[0]-a[0])*t,a[1]+(b[1]-a[1])*t),(a[0]+(b[0]-a[0])*u,a[1]+(b[1]-a[1])*u)],fill=(150,140,130),width=4)
for i,(p,n) in enumerate(zip(pts,names)):
    x,y=p; lock=i>2
    d.regular_polygon((x,y,34),8,rotation=22.5,fill=(60,20,24) if i==0 else (30,26,38),outline=RED if i==0 else (120,110,105),width=3)
    d.text((x,y),"🔒" if False else ("×" if lock else str(i+1)),font=pix(30),fill=(110,100,95) if lock else PAPER,anchor="mm")
    d.text((x,y+56),n,font=pix(20),fill=PAPER if not lock else (110,100,95),anchor="mm")
    if not lock: d.text((x,y-52),"★"*(3-i)+"☆"*i,font=ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",20),fill=(220,180,80),anchor="mm")
d.text((80,660),"<  Back",font=pix(28),fill=(170,160,145))
d.rectangle([1000,630,1200,690],fill=RED); d.text((1100,660),"Enter",font=pix(30),fill=PAPER,anchor="mm")
im.save("ui-mockups/level_select.png")
# gameplay hud
im=bg(0); d=ImageDraw.Draw(im)
d.rectangle([0,600,W,H],fill=INK); d.rectangle([520,470,760,490],fill=INK)
for x in range(0,W,64): d.line([(x,600),(x+30,604)],fill=(50,44,58),width=2)
ninja(d,400,570,1.6,1); 
ninja(d,860,570,1.5,-1); d.polygon([(820,486),(900,486),(860,466)],fill=INK); d.ellipse([846,512,852,518],fill=RED)
for i in range(5): d.text((40+i*42,40),"●",font=ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",34),fill=RED if i<4 else (60,50,60),anchor="lm")
d.text((68,85),"x 12",font=pix(26),fill=PAPER,anchor="lm")
d.text((W/2,40),"Bamboo Gate",font=brush(48),fill=PAPER,anchor="mm")
d.text((W-110,40),"02:14",font=pix(28),fill=PAPER,anchor="mm")
d.rectangle([W-60,22,W-50,58],fill=PAPER); d.rectangle([W-42,22,W-32,58],fill=PAPER)
def tb(x,y,r,t):
    o=Image.new("RGBA",(W,H),(0,0,0,0)); ImageDraw.Draw(o).ellipse([x-r,y-r,x+r,y+r],fill=(10,18,20,150)); im.paste(o,(0,0),o)
    d.ellipse([x-r,y-r,x+r,y+r],outline=(226,214,190),width=4); d.text((x,y),t,font=pix(int(r*0.55)),fill=PAPER,anchor="mm")
tb(110,610,58,""); tb(250,610,58,""); d.polygon([(90,610),(125,585),(125,635)],fill=PAPER); d.polygon([(270,610),(235,585),(235,635)],fill=PAPER)
tb(1170,600,70,"JUMP"); tb(1030,640,56,"SLASH"); tb(1060,500,46,""); d.regular_polygon((1060,500,22),4,rotation=45,fill=PAPER); d.regular_polygon((1060,500,22),4,fill=PAPER); d.ellipse([1054,494,1066,506],fill=INK)
grass(d,0,W,600); grass(d,520,760,470)
for x in range(600,760,16): d.polygon([(x,600),(x+8,572),(x+16,600)],fill=RED)
d.regular_polygon((48,85,12),4,fill=(120,220,210))
for k in range(30):
    x=random.randint(0,W); y=random.randint(0,600); d.ellipse([x,y,x+3,y+3],fill=(200,230,220))
im.save("ui-mockups/gameplay_hud.png")
