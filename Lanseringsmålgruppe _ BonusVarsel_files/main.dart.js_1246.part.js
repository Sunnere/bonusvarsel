((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,A,C,B={
uS(d,e){var x,w=new B.dLB(A.a1(d,e,16)),v=$.rM0
w.b=v==null?$.rM0=A.bm($.Iuc,null):v
x=document.createElement("bottom-bar")
w.c=x
return w},
Jo4(d,e){return new B.eZc(A.r(d,e,y.s))},
Jo5(d,e){return new B.eZd(A.r(d,e,y.s))},
Jo6(d,e){return new B.eZe(A.S(),A.r(d,e,y.s))},
Jo7(d,e){return new B.eZf(A.r(d,e,y.s))},
dLB:function dLB(d){var _=this
_.y=_.x=_.w=_.r=_.f=_.e=$
_.ay=_.ax=_.at=_.as=_.Q=_.z=null
_.c=_.b=_.a=_.CW=_.ch=$
_.d=d},
eZc:function eZc(d){var _=this
_.d=_.c=_.b=$
_.e=null
_.a=d},
eZd:function eZd(d){this.c=this.b=$
this.a=d},
eZe:function eZe(d,e){var _=this
_.b=d
_.d=_.c=$
_.a=e},
lQy:function lQy(d){this.a=d},
eZf:function eZf(d){this.c=this.b=$
this.a=d}},D
J=c[1]
A=c[0]
C=c[2]
B=a.updateHolder(c[1570],B)
D=c[1677]
B.dLB.prototype={
gu(){return"BottomBarComponent"},
gcU(){var x=y.h
return A.a([A.a([],x),A.a([],x)],y.v)},
t(){var x,w,v,u,t,s,r,q=this,p=q.af(),o=q.e=D.nqs(q,0),n=q.ch=o.c
p.appendChild(n)
o.a6("bottom-bar-base")
x=q.d
w=x.a
x=x.b
x=D.nqr(w.i(C.n,x),n,w.i(C.bZ,x),w.i(C.h,x),n,w.i(A.H(C.f,A.M()),x))
q.f=x
v=document
u=v.createElement("div")
q.U(u,"pc-space-between pc-wrap pc-end-aligned-last pc-flex")
t=A.Y(v,u)
q.U(t,"content")
s=A.Y(v,t)
q.U(s,"status-icon")
q.r=A.w(q,4,s,B.DsP())
q.w=A.w(q,5,s,B.DsQ())
n=q.CW=A.bS(v,t)
A.c(n,"aria-live","polite")
q.U(n,"message margin-right")
A.N(t," ")
q.x=A.w(q,8,t,B.DsR())
r=A.Y(v,u)
q.U(r,"button-container gm3-button")
q.cg(r,0)
q.y=A.w(q,10,r,B.DsS())
o.q(x,A.a([A.a([u],y.h)],y.v))},
v(){var x,w,v,u,t,s,r,q,p=this,o="action-triggered",n=p.a,m=(p.d.f&1)!==0,l=n.b,k=p.as!==l
if(k){p.f.sbI(0,l)
p.as=l}if(m)p.f.G()
x=p.r
w=n.d!=null&&!n.w
x.c.sI(w)
w=p.w
w.c.sI(n.w)
v=p.x
v.c.sI(n.f!=null)
u=p.y
u.c.sI(n.x==null)
x.a.C()
w.a.C()
v.a.C()
u.a.C()
t=n.ga2O()
if(p.z!==t){A.aj(p.ch,o,t)
p.z=t
k=!0}s=!n.c
if(p.Q!==s){A.aj(p.ch,"always-full-width",s)
p.Q=s
k=!0}x=p.e
x.R(m)
r=n.ga2O()
if(p.at!==r){A.aj(p.CW,o,r)
p.at=r
k=!0}q=n.e
if(p.ax!=q){p.CW.innerHTML=A.id(q)
p.ax=q
k=!0}x.l()
$.u().F(k)},
B(){var x=this
x.r.a.D()
x.w.a.D()
x.x.a.D()
x.y.a.D()
x.e.m()
x.f.A()},
R(d){var x=this,w=x.a.ga2O(),v=x.ay!==w
if(v){A.aj(x.c,"action-triggered",w)
x.ay=w}$.u().F(v)}}
B.eZc.prototype={
gu(){return"BottomBarComponent"},
t(){var x,w=this,v=w.c=A.ek(w,0),u=v.c
A.c(u,"debug-id","status-icon")
w.gZ().a_(u)
x=new A.e9()
w.d=x
v.P(0,x)
w.K(u)},
W(d,e,f){var x
if(d===C.a3&&0===e){x=this.b
return x===$?this.b=new A.cv(A.J(y.u,y.g)):x}return f},
v(){var x=this,w=x.a.a.d,v=x.e!=w
if(v){x.d.saV(0,w)
x.e=w}if(v)x.c.d.f|=32
x.c.l()
$.u().F(v)},
B(){this.c.m()}}
B.eZd.prototype={
gu(){return"BottomBarComponent"},
t(){var x,w=this,v=w.b=A.i6(w,0),u=v.c
v.a6("spinner")
x=new A.hR()
w.c=x
v.P(0,x)
w.K(u)},
v(){this.b.l()},
B(){this.b.m()}}
B.eZe.prototype={
gu(){return"BottomBarComponent"},
t(){var x,w=this,v=w.c=A.aR(w,0),u=v.c
v.a6("mdc-button mdc-button--text gm3-button")
A.c(u,"debug-id","link-button")
x=A.aQ(u)
w.d=x
v.q(x,A.a([A.a([w.b.b],y.h)],y.v))
x=y.k
J.an(u,"click",w.aq(new B.lQy(w),x,x))
w.K(u)},
v(){var x=this.a.a.f
if(x==null)x=""
this.b.a8(x)
this.c.l()},
B(){this.c.m()}}
B.eZf.prototype={
gu(){return"BottomBarComponent"},
t(){var x,w,v=this,u=v.b=A.b0(v,0),t=u.c
v.gZ().a_(t)
x=v.a
w=x.c
w=A.b_(t,u,w.gh().i(A.H(C.f,A.M()),w.gj()),w.gh().i(C.r,w.gj()),w.gh().p(C.t,w.gj()),w.gh().p(C.y,w.gj()))
v.c=w
x=x.e
if(1>=x.length)return A.G(x,1)
u.q(w,A.a([x[1]],y.v))
v.K(t)},
v(){var x,w=this,v=(w.a.Q&1)!==0
if(v)w.c.b=!0
if(v)w.b.d.f|=32
if(v)w.c.G()
w.c.aB()
x=w.b
x.R(v)
x.l()
$.u().F(v)},
B(){this.b.m()
this.c.A()}}
var z=a.updateTypes(["m<~>(j,E)"])
B.lQy.prototype={
$1(d){this.a.a.a.r.Y(0,d)},
$S:0};(function installTearOffs(){var x=a._static_2
x(B,"DsP","Jo4",0)
x(B,"DsQ","Jo5",0)
x(B,"DsR","Jo6",0)
x(B,"DsS","Jo7",0)})();(function inheritance(){var x=a.inherit,w=a.inheritMany
x(B.dLB,A.b1)
w(A.m,[B.eZc,B.eZd,B.eZe,B.eZf])
x(B.lQy,A.aK)})()
A.ak(b.typeUniverse,JSON.parse('{"dLB":{"j":[]},"eZc":{"m":["pm"],"j":[],"p":[]},"eZd":{"m":["pm"],"j":[],"p":[]},"eZe":{"m":["pm"],"j":[],"p":[]},"eZf":{"m":["pm"],"j":[],"p":[]}}'))
var y={s:A.q("pm"),k:A.q("bA"),v:A.q("t<O<B>>"),h:A.q("t<B>"),g:A.q("fs"),u:A.q("fZ")};(function staticFields(){$.rM0=null
$.Iuc=A.a([$.uSw],y.h)})()};
(a=>{a["Y8fW57SaBqeX0MWpjOYI1sEGFWU="]=a.current})($__dart_deferred_initializers__);
//# sourceMappingURL=main.dart.js_1246.part.js.map
