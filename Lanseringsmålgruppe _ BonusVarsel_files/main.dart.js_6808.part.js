((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var A,C,E,F,G,B={
btT(){var x=new B.b_n()
x.T()
return x},
b_n:function b_n(){this.a=$},
d4b(){var x=null
return new B.cAq(A.bSp(),A.b("Invites paused",x,x,x,x),A.b("All batches paused",x,x,x,x))},
cAq:function cAq(d,e,f){var _=this
_.c=_.b=_.a=null
_.d=d
_.r=_.f=_.e=0
_.w=e
_.x=f},
i3K:function i3K(){},
i3L:function i3L(){},
i3M:function i3M(){},
i3N:function i3N(){},
i3O:function i3O(){},
i3P:function i3P(){},
d4a:function d4a(d,e){this.a=d
this.b=e},
d4c(d,e){var x,w=new B.dEX(A.a1(d,e,16)),v=$.rDL
w.b=v==null?$.rDL=A.aa(C.a,null):v
x=document.createElement("acquisition-method-summary")
w.c=x
return w},
J6T(d,e){return new B.eH_(A.r(d,e,y.u))},
J6U(d,e){return new B.eH0(A.S(),A.r(d,e,y.u))},
dEX:function dEX(d){var _=this
_.f=_.e=$
_.r=null
_.c=_.b=_.a=$
_.d=d},
eH_:function eH_(d){var _=this
_.e=_.d=_.c=_.b=$
_.f=null
_.a=d},
eH0:function eH0(d,e){this.b=d
this.a=e},
mGu(d){var x=null
return A.aA(d,A.a([d],y.h),x,x,x,x,"countriesStatusMessage","1 country / region",""+d+" countries / regions",x,x,x)},
nNJ(d){var x=null,w=d.a,v=w.k(12),u=w.k(2)
switch(v){case C.pR:if(u===C.fW)return B.nFh(w.k(2),w.k(1).a.O(0))
if(u===C.fn)return B.tZE(w.k(1).a.O(0))
w=w.k(1).a.O(0)
return A.b("Staged release "+w+" in review",x,"_stagedReleaseInReviewStatusMessage",A.a([w],y.h),x)
case C.oy:return B.u_U(w.k(1).a.O(0))
case C.zK:if(w.k(1).a.O(0).length===0)w=$.rd8()
else{w=w.k(1).a.O(0)
w=A.b("Draft release: "+w,x,"_draftReleaseStatusMessageTitled",A.a([w],y.h),x)}return w
default:return B.nFh(w.k(2),w.k(1).a.O(0))}},
tZE(d){return A.b("Release "+d+" in review",null,"_fullReleaseInReviewStatusMessage",A.a([d],y.h),null)},
u_U(d){return A.b("Release "+d+" rejected",null,"_rejectedReleaseStatusMessage",A.a([d],y.h),null)},
nFh(d,e){var x="Latest release: "+e
return F.nF(d,A.T(["RELEASE_STATUS_STAGED_ROLLOUT",x,"RELEASE_STATUS_FULLY_ROLLED_OUT",x,"RELEASE_STATUS_HALTED","Release halted ("+e+")","other","unsupported"],y.E,y.w),A.a([d,e],y.h),null,null,"_approvedLatestReleaseStatusMessage")}},D
A=c[0]
C=c[2]
E=c[1634]
F=c[1502]
G=c[1682]
B=a.updateHolder(c[912],B)
D=c[2256]
B.b_n.prototype={
S(d){return A.z(this,y.q)},
gN(){return $.zxd()}}
B.cAq.prototype={
saQH(d){var x
if(d==null)return
x=d.a
if(x.length!==0)this.e=new A.K(x,new B.i3K(),A.a5(x).n("K<1,E>")).ci(0,new B.i3L())
this.zf()},
samd(d){var x
if(d!=null){if(d.gaUT().gdjt().gdju().a.length!==0){x=d.gaUT().gdjt().gdju()
x=new A.K(x,new B.i3M(),x.$ti.n("K<a7.E,bJ>")).ci(0,new B.i3N()).aD(0)}else x=0
this.f=x
if(d.gaUT().gde4().a.length!==0){x=d.gaUT().gde4()
x=new A.K(x,new B.i3O(),x.$ti.n("K<a7.E,bJ>")).ci(0,new B.i3P()).aD(0)}else x=0
this.r=x}this.zf()},
zf(){var x=this
if(!x.gdjT())return
x.d=x.b.a.k(4).a.k(7)
x.a=x.eaQ()},
eaQ(){var x,w,v,u=this,t=null,s="failed precondition",r="_numberOfUsersJoinedLabel"
switch(u.c){case D.aGg:if(!u.d.a.a3(1)){x=A.aO("Access codes config missing!",s)
x.toString
A.ae(A.b4(x))}x=A.a([],y.x)
w=u.e
if(w>0){w=$.d1z().ar(w)
x.push(A.b(w+" codes generated",t,"_numberOfCodesGeneratedLabel",A.a([w],y.h),t))}if(u.d.a.k(1).a.ah(1).aD(0)>0){w=$.d1z().ar(u.d.a.k(1).a.ah(1).aD(0))
x.push(A.b(w+" users joined",t,r,A.a([w],y.h),t))}if(!u.d.a.k(1).a.am(0)&&u.e>0)x.push(u.x)
return A.ag(x,y.w)
case D.aGh:if(!u.d.a.a3(0)){x=A.aO("Open access config missing!",s)
x.toString
A.ae(A.b4(x))}x=u.d.a.k(0).a
if(x.ah(0).ab(0,$.v7i()))v=$.v7h()
else{x=$.d1z().ar(x.ah(0).aD(0))
v=A.b(x+" users eligible",t,"_limitedOpenInviteLabel",A.a([x],y.h),t)}x=A.a([v],y.x)
if(u.d.a.k(0).a.ah(2).aD(0)>0){w=$.d1z().ar(u.d.a.k(0).a.ah(2).aD(0))
x.push(A.b(w+" users joined",t,r,A.a([w],y.h),t))}if(!u.d.a.k(0).a.am(1))x.push(u.w)
return A.ag(x,y.w)
case D.aGi:if(!u.d.a.a3(2)){x=A.aO("Pre-reg invites config missing!",s)
x.toString
A.ae(A.b4(x))}x=A.a([],y.x)
w=u.r
if(w>0){w=$.d1z().ar(w)
x.push(A.b(w+" eligible users",t,"_numberOfEligibleUsersLabel",A.a([w],y.h),t))}w=u.f
if(w>0){w=$.d1z().ar(w)
x.push(A.b(w+" pre-registered users invited",t,"_numberOfPreRegisteredUsersInvitedLabel",A.a([w],y.h),t))}if(!u.d.a.k(2).a.am(0)&&u.f>0)x.push(u.w)
return A.ag(x,y.w)
default:throw A.a0(A.as("Invalid acquisition method!",t))}},
gdjT(){var x=this.b
return x!=null&&x.a.a3(4)&&this.b.a.k(4).a.a3(7)&&this.c!=null}}
B.d4a.prototype={
b6(){return"AcquisitionMethod."+this.b}}
B.dEX.prototype={
gu(){return"AcquisitionMethodSummaryComponent"},
t(){var x=this,w=x.e=new A.Z(0,x,A.af(x.af())),v=x.d
x.f=new G.c7(w,new A.a8(w,B.D54()),v.a.i(C.L,v.b))},
v(){var x=this,w=!x.a.gdjT(),v=x.r!==w
if(v){x.f.sbN(w)
x.r=w}x.e.C()
$.u().F(v)},
B(){this.e.D()}}
B.eH_.prototype={
gu(){return"AcquisitionMethodSummaryComponent"},
t(){var x,w=this,v=w.b=E.l4(w,0),u=v.c,t=w.a.c
t=E.l3(t.gh().i(C.n,t.gj()),u)
w.c=t
x=w.d=new A.Z(1,w,A.bh())
w.e=new A.bd(x,new A.a8(x,B.D55()))
v.q(t,A.a([A.a([x],y.h)],y.v))
w.K(u)},
v(){var x,w,v=this,u=v.a,t=u.Q
if((t&1)!==0)v.c.G()
x=u.a.a
w=v.f!=x
if(w){v.e.sbb(x)
v.f=x}v.e.au()
v.d.C()
v.b.l()
$.u().F(w)},
B(){this.d.D()
this.b.m()
this.c.A()}}
B.eH0.prototype={
gu(){return"AcquisitionMethodSummaryComponent"},
t(){var x=document.createElement("li")
x.appendChild(this.b.b)
this.K(x)},
v(){this.b.a8(this.a.f.E(0,"$implicit"))}}
var z=a.updateTypes(["m<~>(j,E)","E(ys)","bJ(Dp)","bJ(Pv)","b_n()"])
B.i3K.prototype={
$1(d){return d.ghJN().aD(0)},
$S:z+1}
B.i3L.prototype={
$2(d,e){return d+e},
$S:46}
B.i3M.prototype={
$1(d){return d.gh00()},
$S:z+2}
B.i3N.prototype={
$2(d,e){return d.dF(0,e)},
$S:90}
B.i3O.prototype={
$1(d){return d.gfNk()},
$S:z+3}
B.i3P.prototype={
$2(d,e){return d.dF(0,e)},
$S:90};(function installTearOffs(){var x=a._static_0,w=a._static_2
x(B,"IXb","btT",4)
w(B,"D54","J6T",0)
w(B,"D55","J6U",0)})();(function inheritance(){var x=a.inherit,w=a.inheritMany
x(B.b_n,A.x)
x(B.cAq,A.B)
w(A.aK,[B.i3K,B.i3M,B.i3O])
w(A.el,[B.i3L,B.i3N,B.i3P])
x(B.d4a,A.dM)
x(B.dEX,A.b1)
w(A.m,[B.eH_,B.eH0])})()
A.ak(b.typeUniverse,JSON.parse('{"b_n":{"x":[]},"dEX":{"j":[]},"eH_":{"m":["cAq"],"j":[],"p":[]},"eH0":{"m":["cAq"],"j":[],"p":[]},"Pv":{"x":[]},"Dp":{"x":[]},"bbP":{"x":[]}}'))
var y={u:A.q("cAq"),v:A.q("t<O<B>>"),h:A.q("t<B>"),x:A.q("t<n>"),E:A.q("B"),w:A.q("n"),q:A.q("b_n")};(function constants(){D.aGg=new B.d4a(0,"inviteCodes")
D.aGh=new B.d4a(1,"openInvites")
D.aGi=new B.d4a(2,"preRegInvites")})();(function staticFields(){$.rDL=null})();(function lazyInitializers(){var x=a.lazyFinal
x($,"Qw4","zxd",()=>{var w=null,v=A.A("UpdateTrackRequest",B.IXb(),w,w,C.bL,w,w)
v.L(1,"track",A.amI(),A.q("lI"))
v.L(2,"updateMask",A.kj(),A.q("kT"))
return v})
x($,"LqE","v7i",()=>A.dp(-1))
x($,"LqC","d1z",()=>A.eP(null))
x($,"LqD","v7h",()=>{var w=null
return A.b("Unlimited users invited",w,w,w,w)})
x($,"RGq","ng0",()=>{var w=null
return A.b("Active",w,w,w,w)})
x($,"Sp5","nkk",()=>{var w=null
return A.b("Inactive",w,w,w,w)})
x($,"RaW","rd8",()=>{var w=null
return A.b("Draft release",w,w,w,w)})})()};
(a=>{a["Ebl1vkt89PflfvHGb+iSdCdtTs8="]=a.current})($__dart_deferred_initializers__);
//# sourceMappingURL=main.dart.js_6808.part.js.map
