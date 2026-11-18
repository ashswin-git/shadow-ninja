# Original procedural NA2-style (silhouette + fog) art. CC0, generated here.
import random, math
from PIL import Image, ImageDraw, ImageFilter
R='assets/'
W,H=1280,720
PAL={
 'snow':  dict(top=(52,79,107),bot=(124,152,154),far=(85,107,125),mid=(52,72,92),near=(18,26,34),acc=(116,47,82),ray=(220,240,255)),
 'forest':dict(top=(42,63,80),bot=(125,137,127),far=(94,112,108),mid=(58,76,74),near=(16,22,22),acc=(224,176,80),ray=(235,245,220)),
 'boss':  dict(top=(40,8,18),bot=(150,44,52),far=(96,30,42),mid=(58,16,28),near=(14,4,8),acc=(236,240,251),ray=(255,210,200)),
}
def grad(c1,c2):
    im=Image.new('RGBA',(W,H)); d=ImageDraw.Draw(im)
    for y in range(H):
        t=y/H; d.line([(0,y),(W,y)],fill=tuple(int(c1[i]+(c2[i]-c1[i])*t) for i in range(3))+(255,))
    return im
def wrap_poly(d,pts,fill):
    for off in (-W,0,W): d.polygon([(x+off,y) for x,y in pts],fill=fill)
def ridge(base,amp,step,seed):
    random.seed(seed); pts=[(0,H)]; y=base
    for x in range(0,W+step,step):
        y=base+amp*math.sin(x/W*2*math.pi*2+seed)+random.randint(-amp//3,amp//3)
        pts.append((x,y))
    pts[-1]=(W,pts[1][1]); pts.append((W,H)); return pts
def trees(d,col,n,ymin,ymax,wmin,wmax,seed,snow=None,bare=False):
    random.seed(seed)
    for i in range(n):
        x=random.randint(0,W); y=random.randint(ymin,ymax); w=random.randint(wmin,wmax)
        for off in (-W,0,W):
            X=x+off
            d.rectangle([X-w//6,y,X+w//6,H],fill=col)
            if bare:
                for k in range(4):
                    yy=y+k*30+20; s=random.choice([-1,1]); d.line([(X,yy),(X+s*w*1.2,yy-40)],fill=col,width=max(2,w//8))
            else:
                for k in range(5):
                    yy=y+k*w*0.55; ww=w*(0.5+k*0.28)
                    d.polygon([(X,yy-w*0.7),(X-ww,yy+w*0.5),(X+ww,yy+w*0.5)],fill=col)
                    if snow and k<4: d.polygon([(X,yy-w*0.7),(X-ww*0.5,yy-w*0.05),(X+ww*0.5,yy-w*0.05)],fill=snow)
def fogband(y,h,col,a):
    im=Image.new('RGBA',(W,H)); d=ImageDraw.Draw(im)
    for i in range(h):
        t=1-abs(i-h/2)/(h/2); d.line([(0,y+i),(W,y+i)],fill=col+(int(a*t),))
    return im
for name,p in PAL.items():
    sky=grad(p['top'],p['bot']); d=ImageDraw.Draw(sky)
    random.seed(1)
    for i in range(90): x=random.randint(0,W);y=random.randint(0,380); d.point((x,y),fill=(255,255,255,random.randint(60,160)))
    sky.save(R+f'na2/{name}_sky.png')
    far=Image.new('RGBA',(W,H)); d=ImageDraw.Draw(far)
    wrap_poly(d,ridge(360,50,40,3),p['far']+(255,))
    if name=='snow':  # palisade posts + chain silhouettes in far layer (original)
        for x in range(0,W,64): d.rectangle([x,300+(x*7)%40,x+40,H],fill=tuple(min(255,c+10) for c in p['far'])+(255,))
    far=Image.alpha_composite(far,fogband(380,260,p['bot'],170)); far.save(R+f'na2/{name}_far.png')
    mid=Image.new('RGBA',(W,H)); d=ImageDraw.Draw(mid)
    trees(d,p['mid']+(255,),14,260,380,22,40,7,snow=(150,170,180,255) if name=='snow' else None,bare=(name=='forest'))
    if name=='boss':
        for x in range(80,W,220):  # torii-like posts (generic)
            d.rectangle([x,330,x+14,H],fill=p['mid']+(255,)); d.rectangle([x+90,330,x+104,H],fill=p['mid']+(255,)); d.rectangle([x-20,320,x+124,334],fill=p['mid']+(255,))
    mid=Image.alpha_composite(mid,fogband(470,220,p['bot'],140)); mid.save(R+f'na2/{name}_mid.png')
    near=Image.new('RGBA',(W,H)); d=ImageDraw.Draw(near)
    trees(d,(0,0,0,255),4,180,300,30,46,11,bare=True)
    near.save(R+f'na2/{name}_near.png')
    rays=Image.new('RGBA',(W,H)); d=ImageDraw.Draw(rays); random.seed(5)
    for i in range(7):
        x=random.randint(-100,W); w=random.randint(40,120)
        d.polygon([(x,0),(x+w,0),(x+w+360,H),(x+360,H)],fill=p['ray']+(random.randint(18,34),))
    rays=rays.filter(ImageFilter.GaussianBlur(18)); rays.save(R+f'na2/{name}_rays.png')
mist=Image.new('RGBA',(W,260)); d=ImageDraw.Draw(mist); random.seed(9)
for i in range(90):
    x=random.randint(-200,W); y=random.randint(60,200); w=random.randint(160,420)
    for off in (-W,0,W): d.ellipse([x+off,y,x+off+w,y+random.randint(24,60)],fill=(255,255,255,random.randint(14,30)))
mist.filter(ImageFilter.GaussianBlur(16)).save(R+'na2/mist.png')
Image.new('RGBA',(32,32),(0,0,0,255)).save(R+'sprites/tile.png')
# snow rim cap
s=Image.new('RGBA',(32,16)); d=ImageDraw.Draw(s); d.rectangle([0,6,31,11],fill=(236,240,251,255))
for x in range(0,32,8): d.polygon([(x,11),(x+4,15),(x+8,11)],fill=(236,240,251,255))
s.save(R+'sprites/snow_rim.png')
# disc ring texture for touch buttons (light rim, grey disc) 256px
b=Image.new('RGBA',(256,256)); d=ImageDraw.Draw(b)
d.ellipse([4,4,251,251],fill=(40,44,52,150),outline=(220,226,236,220),width=6)
d.ellipse([18,18,237,237],outline=(255,255,255,60),width=2)
b.save(R+'na2/disc.png')
print('ok')
