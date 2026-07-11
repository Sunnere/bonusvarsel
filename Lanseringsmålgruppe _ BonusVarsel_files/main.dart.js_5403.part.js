((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,A,B,D,E,C={b6J:function b6J(d){this.a=d},
nAF(d,e,f,g){var x=A.bW(A.a([],y.a),y.r)
return new C.cNL(x,new A.F(null,null,y.i),d,e,f,g)},
Cpb(d){return A.b("Select form factors. "+d,null,"_releaseTypesSelectorAriaLabel",A.a([d],y.h),"Aria label for a button.")},
cNL:function cNL(d,e,f,g,h,i){var _=this
_.a=null
_.b=d
_.d=_.c=!1
_.e=e
_.f=null
_.w=_.r=!1
_.x=f
_.y=g
_.z=h
_.Q=i},
nAG(d,e){var x,w=new C.eps(A.a1(d,e,16)),v=$.tDl
w.b=v==null?$.tDl=A.aa(B.a,null):v
x=document.createElement("release-type-selector")
w.c=x
return w},
KH2(d,e){return new C.hl8(A.r(d,e,y.l))},
eps:function eps(d){var _=this
_.c=_.b=_.a=_.e=$
_.d=d},
hl8:function hl8(d){var _=this
_.c=_.b=$
_.f=_.e=_.d=null
_.a=d},
nKZ(d,e,f,g,h){var x,w=[$.B4d(),$.BdP()]
if(C.hSX(B.xr,d,e))w.push("Wear OS")
if(C.hSX(B.vc,d,e))w.push("Android TV")
x=J.ig(e,B.tB)
if(!x)w.push(h?"Desktop":"Chrome OS")
if(C.hSX(B.jO,d,e))w.push("Google Play Games on PC")
if(g)w.push("Android Auto")
if(C.hSX(B.vb,d,e))w.push("Android XR")
if(C.hSX(B.tC,d,e))w.push("Android Automotive OS")
if(f)w.push("AI Glasses")
return B.p.d0(A.dU(w,y.b).b.bU(0,", "))},
hSX(d,e,f){var x=!1
if(e.b.a9(0,d)){x=J.ig(f,d)
x=!x}return x}},F
J=c[1]
A=c[0]
B=c[2]
D=c[1619]
E=c[2072]
C=a.updateHolder(c[791],C)
F=c[1051]
C.b6J.prototype={}
C.cNL.prototype={
sajK(d){var x=null,w=d==null
if(!(w||!d.b.a9(0,B.oB)))A.ae(A.as(A.aO(x,x),x))
w=w?x:d.b.fg(0,!0)
this.f=w
if(w!=null)J.w7(w,this.ge62())
w=this.f
if(w!=null)J.iS(w,B.oB)},
gou(){var x=this.NH(this.a)
return A.b("Select form factors. "+x,null,"_releaseTypesSelectorAriaLabel",A.a([x],y.h),"Aria label for a button.")},
G(){var x=0,w=A.i(y.v),v=this,u,t
var $async$G=A.d(function(d,e){if(d===1)return A.e(e,w)
for(;;)switch(x){case 0:u=v.z
t=y.e
x=2
return A.D(u.a.c6(0).cB(0,u.gcoK(),t),$async$G)
case 2:v.r=e
x=3
return A.D(v.Q.cO(B.l6,t),$async$G)
case 3:v.w=e
return A.f(null,w)}})
return A.h($async$G,w)},
I9(d){return this.fX7(d)},
fX7(d){var x=0,w=A.i(y.v),v,u=this
var $async$I9=A.d(function(e,f){if(e===1)return A.e(f,w)
for(;;)switch(x){case 0:if(d==null||d===u.a){x=1
break}x=d===B.oB?3:4
break
case 3:x=5
return A.D(u.y.br(0,$.YL().cp(A.aF(u.x),F.ant(E.vM))),$async$I9)
case 5:x=1
break
case 4:u.e.Y(0,d)
case 1:return A.f(v,w)}})
return A.h($async$I9,w)},
NH(d){var x,w,v,u,t=this
if(d===B.oB)return $.yKH()
x=$.yKJ()
d.toString
x=x.b
if(!x.b1(0,d))throw A.a0(A.as("Unsupported form factor",null))
if(d===B.cV){x=t.b
w=t.f
w.toString
v=t.c
u=t.w
return C.nKZ(x,w,t.d,v,u)}if(d===B.jO)return t.r?$.rj_():$.riS()
if(d===B.tB)return t.w?$.AEQ():$.rki()
x=x.E(0,d)
x.toString
return x},
hE5(d){return $.yKI().b.E(0,d)},
e63(d,e){if(d===B.cV)return-1
if(e===B.cV)return 1
return B.p.bL(this.NH(d),this.NH(e))}}
C.eps.prototype={
gu(){return"ReleaseTypeSelectorComponent"},
t(){this.e=A.w(this,0,this.af(),C.Ic5())},
v(){var x=this.a,w=this.e,v=x.a
x=v!=null&&x.f!=null&&v!==B.kX
w.c.sI(x)
w.a.C()},
B(){this.e.a.D()}}
C.hl8.prototype={
gu(){return"ReleaseTypeSelectorComponent"},
t(){var x,w=this,v=w.a,u=y.r,t=w.b=D.md(w,0,u),s=t.c,r=v.c
u=w.c=D.mc(new A.ad(t,null),r.gh().i(B.i,r.gj()),u)
t.P(0,u)
u=u.r
t=y.s
x=new A.k(u,A.v(u).n("k<1>")).J(0,w.X(v.a.gX8(),t,t))
w.a4(A.a([s],y.h),A.a([x],y.q))},
v(){var x,w,v,u,t=this,s=t.a,r=s.a,q=(s.Q&1)!==0
if(q){s=t.c
s.ay=!1
s.cy=r.ghE3()
s.db=r.ghE4()}x=C.Cpb(r.NH(r.a))
if(t.d!==x){t.d=t.c.Q=x
w=!0}else w=q
v=r.f
s=t.e
if(s==null?v!=null:s!==v){t.e=t.c.ax=v
w=!0}u=r.a
if(t.f!=u){t.c.sfp(u)
t.f=u
w=!0}t.b.l()
$.u().F(w)},
B(){this.b.m()}}
var z=a.updateTypes(["~(jo?)","n(jo?)","@(jo)","E(jo,jo)","m<~>(j,E)"]);(function installTearOffs(){var x=a._instance_1u,w=a._instance_2u,v=a._static_2
var u
x(u=C.cNL.prototype,"gX8","I9",0)
x(u,"ghE3","NH",1)
x(u,"ghE4","hE5",2)
w(u,"ge62","e63",3)
v(C,"Ic5","KH2",4)})();(function inheritance(){var x=a.inherit
x(C.b6J,A.ed)
x(C.cNL,A.B)
x(C.eps,A.b1)
x(C.hl8,A.m)})()
A.ak(b.typeUniverse,JSON.parse('{"b6J":{"ed":[]},"eps":{"j":[]},"hl8":{"m":["cNL"],"j":[],"p":[]}}'))
var y=(function rtii(){var x=A.q
return{h:x("t<B>"),a:x("t<jo>"),q:x("t<bt<~>>"),r:x("jo"),l:x("cNL"),i:x("F<jo>"),e:x("I"),b:x("@"),s:x("jo?"),v:x("~")}})();(function staticFields(){$.tDl=null})();(function lazyInitializers(){var x=a.lazyFinal
x($,"RRw","Aw7",()=>{var w=null
return A.b("Automotive OS only",w,w,w,w)})
x($,"RSS","riS",()=>{var w=null
return A.b("Google Play Games on PC only",w,w,w,w)})
x($,"RT5","rj_",()=>{var w=null
return A.b("Google Play Games on PC (Windows) only",w,w,w,w)})
x($,"RKG","Asr",()=>{var w=null
return A.b("Android XR only",w,w,w,w)})
x($,"T6_","Bg3",()=>{var w=null
return A.b("Android TV only",w,w,w,w)})
x($,"TcI","Bjp",()=>{var w=null
return A.b("Wear OS only",w,w,w,w)})
x($,"RXx","rki",()=>{var w=null
return A.b("Chrome OS only",w,w,w,w)})
x($,"S65","AEQ",()=>{var w=null
return A.b("Desktop only",w,w,w,w)})
x($,"SMa","B4d",()=>{var w=null
return A.b("Phones",w,w,w,w)})
x($,"T2t","BdP",()=>{var w=null
return A.b("Tablets",w,w,w,w)})
x($,"PBz","yKH",()=>{var w=null
return A.b("Manage form factors",w,w,w,w)})
x($,"PBB","yKJ",()=>{var w=y.r,v=A.q("n")
return A.e2(A.T([B.cV,$.rww(),B.tC,$.Aw7(),B.jO,$.riS(),B.vc,$.Bg3(),B.xr,$.Bjp(),B.tB,$.rki(),B.vb,$.Asr(),B.kX,$.rj_(),B.fM,""],w,v),w,v)})
x($,"PBA","yKI",()=>{var w=y.r,v=A.q("B")
return A.e2(A.T([B.cV,"phonelink",B.tC,"directions_car",B.jO,"laptop",B.vc,"tv",B.xr,"watch",B.tB,"laptop",B.vb,A.f8("cardboard",null,!0,null,!1),B.kX,"laptop"],w,v),w,v)})})()};
(a=>{a["QRAxdwfQSss5FyRTVk6+EjVO+lo="]=a.current})($__dart_deferred_initializers__);
//# sourceMappingURL=main.dart.js_5403.part.js.map
