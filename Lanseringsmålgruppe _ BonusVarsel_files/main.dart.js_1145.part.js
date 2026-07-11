((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var A,E,C,B={Ix:function Ix(d,e){this.a=d
this.b=e},cHf:function cHf(d,e){this.a=d
this.b=e},
d0N(d,e,f){var x,w,v,u,t,s=null,r=" and a width between ",q=" (landscape) or ",p=" (portrait), and each side must be between ",o=d.a
switch(o.k(0)){case C.aYj:x=y.g
if(o.H(1,x).a.length!==2)A.ae(A.as(A.aO("Expected 2 parameters for image too large",s),s))
o=o.H(1,x).a
if(0>=o.length)return A.G(o,0)
o=B.CVG(o[0])
o.toString
return A.b("File size must be "+o+" or smaller",s,"_fileSizeTooLargeMessage",A.a([o],y.h),s)
case C.aYk:x=y.g
if(o.H(1,x).a.length!==2)A.ae(A.as(A.aO("Expected 2 parameters for invalid dimensions",s),s))
w=o.H(1,x).a
if(0>=w.length)return A.G(w,0)
w=w[0]
x=o.H(1,x).a
if(1>=x.length)return A.G(x,1)
return B.tZg(w,x[1])
case C.aYl:x=y.g
if(o.H(1,x).a.length!==3)A.ae(A.as(A.aO("Expected 3 parameters for invalid dimension range",s),s))
if(e===D.c6C){w=o.H(1,x).a
if(0>=w.length)return A.G(w,0)
w=w[0]
v=o.H(1,x).a
if(1>=v.length)return A.G(v,1)
v=v[1]
u=o.H(1,x).a
if(2>=u.length)return A.G(u,2)
u=B.cxE(u[2],!1)
x=o.H(1,x).a
if(2>=x.length)return A.G(x,2)
x=B.cxE(x[2],!0)
return A.b("Screenshot aspect ratio can't exceed "+u+q+x+p+w+" px and "+v+" px",s,"_screenshotDimensionRangeError",A.a([w,v,u,x],y.h),s)}w=o.H(1,x).a
if(0>=w.length)return A.G(w,0)
w=w[0]
v=o.H(1,x).a
if(1>=v.length)return A.G(v,1)
v=v[1]
u=o.H(1,x).a
if(2>=u.length)return A.G(u,2)
u=B.cxE(u[2],!1)
x=o.H(1,x).a
if(2>=x.length)return A.G(x,2)
x=B.cxE(x[2],!0)
return A.b("Image aspect ratio can't exceed "+u+q+x+p+w+" px and "+v+" px",s,"_genericDimensionRangeError",A.a([w,v,u,x],y.h),s)
case C.Wd:return $.Amn()
case C.aYm:x=y.g
if(o.H(1,x).a.length!==3)A.ae(A.as(A.aO("Expected 3 parameters for invalid aspect ratio",s),s))
if(e===D.eXe){w=o.H(1,x).a
if(2>=w.length)return A.G(w,2)
t=A.acR(w[2])
w=t==null?!0:t>1
v=y.h
if(w){w=o.H(1,x).a
if(0>=w.length)return A.G(w,0)
w=w[0]
u=o.H(1,x).a
if(1>=u.length)return A.G(u,1)
u=u[1]
x=o.H(1,x).a
if(2>=x.length)return A.G(x,2)
x=B.cxE(x[2],!1)
v=A.b("Landscape screenshots must have an aspect ratio of "+x+r+w+" px and "+u+" px",s,"_landscapeScreenshotAspectRatioInvalidMessage",A.a([w,u,x],v),s)
o=v}else{w=o.H(1,x).a
if(0>=w.length)return A.G(w,0)
w=w[0]
u=o.H(1,x).a
if(1>=u.length)return A.G(u,1)
u=u[1]
x=o.H(1,x).a
if(2>=x.length)return A.G(x,2)
x=B.cxE(x[2],!1)
v=A.b("Portrait screenshots must have an aspect ratio of "+x+r+w+" px and "+u+" px",s,"_portraitScreenshotAspectRatioInvalidMessage",A.a([w,u,x],v),s)
o=v}return o}if(f===D.ars){w=o.H(1,x).a
if(0>=w.length)return A.G(w,0)
w=w[0]
v=o.H(1,x).a
if(1>=v.length)return A.G(v,1)
v=v[1]
x=o.H(1,x).a
if(2>=x.length)return A.G(x,2)
x=B.cxE(x[2],!1)
return A.b("Animation must have an aspect ratio of "+x+r+w+" px and "+v+" px",s,"_animationAspectRatioInvalidMessage",A.a([w,v,x],y.h),s)}w=o.H(1,x).a
if(0>=w.length)return A.G(w,0)
w=w[0]
v=o.H(1,x).a
if(1>=v.length)return A.G(v,1)
v=v[1]
x=o.H(1,x).a
if(2>=x.length)return A.G(x,2)
x=B.cxE(x[2],!1)
return A.b("Image must have an aspect ratio of "+x+r+w+" px and "+v+" px",s,"_aspectRatioInvalidMessage",A.a([w,v,x],y.h),s)
case C.aYu:throw A.a0(A.as("Error without key, "+d.a1(0),s))
case C.aYn:return $.zTR()
case C.aYo:x=y.g
if(o.H(1,x).a.length!==1)A.ae(A.as(A.aO("Expected 1 parameter for animation frame rate too high",s),s))
o=o.H(1,x).a
if(0>=o.length)return A.G(o,0)
o=o[0]
return A.b("Upload animations with a frame rate of "+o+" fps or less",s,"_animationFrameRateTooHighMessage",A.a([o],y.h),s)
case C.aYt:return A.b("Don't include image files (PNGs or JPGs)",s,"_animationContentInvalidIncludesImagesMessage",s,s)
case C.aYs:return A.b("Don't include text",s,"_animationContentInvalidIncludesTextMessage",s,s)
case C.aYr:return A.b("Don't include layer effects",s,"_animationContentInvalidIncludesLayerEffectsMessage",s,s)
case C.aYg:return $.rqB()
case C.aYp:x=y.g
if(o.H(1,x).a.length!==1)A.ae(A.as(A.aO("Expected 1 parameter for animation content invalid includes unsupported lottie feature",s),s))
o=o.H(1,x).a
if(0>=o.length)return A.G(o,0)
o=o[0]
return A.b("The "+o+" Lottie feature is not supported",s,"_animationContentInvalidIncludesUnsupportedLottieFeatureMessage",A.a([o],y.h),s)
case C.aYi:x=y.g
w=o.H(1,x).a
if(0>=w.length)return A.G(w,0)
w=w[0]
x=o.H(1,x).a
if(1>=x.length)return A.G(x,1)
return B.tZg(w,x[1])
case C.aYh:return $.Akq()
case C.aYq:return $.A4K()}throw A.a0(A.as("Unknown validation error: "+d.a1(0),s))},
tZg(d,e){return A.b("Image dimensions must be "+d+" px by "+e+" px",null,"_exactDimensionsError",A.a([d,e],y.h),null)},
CVG(d){var x=A.acR(d)
if(x==null)return null
return F.lS(x,2)},
cxE(d,e){var x=B.CVF(d,e),w=D.hIB.E(0,x)
return w==null?x:w},
CVF(d,e){var x=A.acR(d)
if(x==null)return""
if(e)x=1/x
return x>1?B.tZD(x)+":1":"1:"+B.tZD(1/x)},
tZD(d){return d===E.F.hf(d)?E.F.im(d,0):E.F.im(d,2)}},D,F
A=c[0]
E=c[2]
C=c[2277]
B=a.updateHolder(c[1430],B)
D=c[2631]
F=c[1601]
B.Ix.prototype={}
B.cHf.prototype={}
var z=a.updateTypes(["n(BS{imageType:Ix?,liveOpsImageType:cHf?})"]);(function installTearOffs(){var x=a.installStaticTearOff
x(B,"uzc",1,function(){return{imageType:null,liveOpsImageType:null}},["$3$imageType$liveOpsImageType","$1","$2$imageType"],["d0N",function(d){return B.d0N(d,null,null)},function(d,e){return B.d0N(d,e,null)}],0,0)})();(function inheritance(){var x=a.inheritMany
x(A.ab,[B.Ix,B.cHf])})()
A.ak(b.typeUniverse,JSON.parse('{"Ix":{"ab":[]},"cHf":{"ab":[]}}'))
var y={h:A.q("t<B>"),g:A.q("n")};(function constants(){D.ars=new B.cHf(3,"IMAGE_TYPE_ANIMATION")
D.eXe=new B.Ix(12,"IMAGE_TYPE_STORE_LISTING_BATTLESTAR_SCREENSHOT")
D.c6C=new B.Ix(5,"IMAGE_TYPE_STORE_LISTING_SCREENSHOT")
D.jKy={"1.78:1":0,"1:1.78":1,"1.33:1":2,"1:1.33":3}
D.hIB=new A.y(D.jKy,["16:9","9:16","4:3","3:4"],A.q("y<n,n>"))})();(function lazyInitializers(){var x=a.lazyFinal
x($,"RBI","Amn",()=>{var w=null
return A.b("File type must be PNG or JPEG",w,w,w,w)})
x($,"R2q","zTR",()=>{var w=null
return A.b("Upload a JSON file",w,w,w,w)})
x($,"Rzt","Akq",()=>{var w=null
return A.b("Invalid SVG file",w,w,w,w)})
x($,"RgH","A4K",()=>{var w=null
return A.b("Image cannot have transparency",w,w,w,w)})})()};
(a=>{a["LCnZGcY4cylaLob/l+/VveYfz2Q="]=a.current})($__dart_deferred_initializers__);
//# sourceMappingURL=main.dart.js_1145.part.js.map
