((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var C,D,A={
d9U(){var w=new A.bXG()
w.T()
return w},
iTw(){var w=new A.azn()
w.T()
return w},
evU(){var w=new A.clq()
w.T()
return w},
liQ(){var w=new A.LA()
w.T()
return w},
bXG:function bXG(){this.a=$},
azn:function azn(){this.a=$},
clq:function clq(){this.a=$},
LA:function LA(){this.a=$},
vm:function vm(d,e){this.a=d
this.b=e},
aZa:function aZa(d,e){this.a=d
this.b=e},
elZ(d,e,f,g){var w,v="developer_id.value",u=x.x,t=C.ai("",null,C.a([v],u))
u=C.ai("contactPreferences",null,C.a([v],u))
w=f.ad($.ywp().ad(g))
return new A.elY(t,u,y.h,d,e,C.J(x.w,x.p),w)},
bod:function bod(){},
elY:function elY(d,e,f,g,h,i,j){var _=this
_.f=d
_.r=e
_.a=f
_.b=g
_.c=h
_.d=i
_.e=j},
dQn:function dQn(d){this.a=d}},B
C=c[0]
D=c[2]
A=a.updateHolder(c[1049],A)
B=c[2133]
A.bXG.prototype={
S(d){return C.z(this,x.m)},
gN(){return $.x78()}}
A.azn.prototype={
S(d){return C.z(this,x.u)},
gN(){return $.w5u()}}
A.clq.prototype={
S(d){return C.z(this,x.h)},
gN(){return $.zdy()}}
A.LA.prototype={
S(d){return C.z(this,x.A)},
gN(){return $.zdz()}}
A.vm.prototype={}
A.aZa.prototype={}
A.bod.prototype={}
A.elY.prototype={
a8c(d){var w=this,v=x.m,u=x.u
return w.aL(C.at(w,w.e.ad(w.f.aN(d).ad(null)),C.ar(y.b,A.mGg(),v,u),y.h,"GetContactPreferences",d,"GET",D.C,v,u),v,u)},
bMg(d){var w=this,v=x.E,u=x.u
return w.aL(C.at(w,w.e.ad(w.r.aN(d).ad(null)),C.ar(y.b,A.mGg(),v,u),y.h,"UpdateContactPreferences",d,"PATCH",D.C,v,u),v,u)}}
A.dQn.prototype={}
var z=a.updateTypes(["bXG()","azn()","clq()","LA()"]);(function installTearOffs(){var w=a._static_0
w(A,"DIf","d9U",0)
w(A,"mGg","iTw",1)
w(A,"nJE","evU",2)
w(A,"ukA","liQ",3)})();(function inheritance(){var w=a.inheritMany,v=a.inherit
w(C.x,[A.bXG,A.azn,A.clq,A.LA])
w(C.ab,[A.vm,A.aZa])
v(A.bod,C.jA)
v(A.elY,C.jD)
v(A.dQn,C.bw)})()
C.ak(b.typeUniverse,JSON.parse('{"bXG":{"x":[]},"b_9":{"x":[]},"azn":{"x":[]},"clq":{"x":[]},"LA":{"x":[]},"vm":{"ab":[]},"aZa":{"ab":[]},"dQn":{"bw":["dH"]}}'))
var y={h:"play.console.platform.api.contacts.ContactsService",b:"v1/developers/{developer_id.value}/contacts"}
var x={p:C.q("e4<@>"),u:C.q("azn"),m:C.q("bXG"),x:C.q("t<n>"),w:C.q("n"),A:C.q("LA"),h:C.q("clq"),E:C.q("b_9")};(function constants(){var w=a.makeConstList
B.a4o=new A.dQn("")
B.bf0=new A.aZa(0,"SCOPE_UNSPECIFIED")
B.a_q=new A.aZa(1,"ALL_APPS")
B.aDj=new A.aZa(2,"SOME_APPS")
B.bf1=new A.aZa(3,"PINNED_APPS")
B.h4n=w([B.bf0,B.a_q,B.aDj,B.bf1],C.q("t<aZa>"))
B.bf2=new A.vm(0,"SUBTOPIC_UNSPECIFIED")
B.a_r=new A.vm(2,"SUBTOPIC_POLICY_ANNOUNCEMENTS")
B.a_s=new A.vm(3,"SUBTOPIC_ENFORCEMENT_EMAILS")
B.ae_=new A.vm(4,"SUBTOPIC_PAYMENTS_AND_COMPLIANCE")
B.ae1=new A.vm(27,"SUBTOPIC_GOOGLE_PLAY_MARKETING")
B.MC=new A.vm(28,"SUBTOPIC_GOOGLE_PLAY_RESEARCH")
B.adU=new A.vm(11,"SUBTOPIC_NEW_ONE_STAR_REVIEW")
B.adV=new A.vm(12,"SUBTOPIC_NEW_TWO_STAR_REVIEW")
B.ae0=new A.vm(13,"SUBTOPIC_NEW_THREE_STAR_REVIEW")
B.adW=new A.vm(14,"SUBTOPIC_NEW_FOUR_STAR_REVIEW")
B.adX=new A.vm(15,"SUBTOPIC_NEW_FIVE_STAR_REVIEW")
B.aDl=new A.vm(16,"SUBTOPIC_REVIEW_UPDATED_SINCE_REPLIED")
B.bf3=new A.vm(18,"SUBTOPIC_NEW_VITALS_ANOMALIES")
B.aDm=new A.vm(19,"SUBTOPIC_CLOUD_TEST_RESULTS_WITH_FAILURES")
B.aDo=new A.vm(20,"SUBTOPIC_CLOUD_TEST_RESULTS_ALL_PASSED")
B.aDk=new A.vm(21,"SUBTOPIC_APP_GO_LIVE")
B.ae2=new A.vm(22,"SUBTOPIC_AB_EXPERIMENT_COMPLETED")
B.adZ=new A.vm(29,"SUBTOPIC_SDK_ISSUES")
B.adY=new A.vm(23,"SUBTOPIC_NEW_BETA_REVIEW")
B.aDn=new A.vm(30,"SUBTOPIC_LIVEOPS_QUALITY_FAILURE_FEEDBACK")
B.hhc=w([B.bf2,B.a_r,B.a_s,B.ae_,B.ae1,B.MC,B.adU,B.adV,B.ae0,B.adW,B.adX,B.aDl,B.bf3,B.aDm,B.aDo,B.aDk,B.ae2,B.adZ,B.adY,B.aDn],C.q("t<vm>"))
B.a9T=new C.dw("play.console.platform.api.contacts")
B.aeY=C.ao("bod")
B.aeZ=C.ao("elY")})();(function lazyInitializers(){var w=a.lazyFinal
w($,"NJM","x78",()=>{var v=null,u=C.A("GetContactPreferencesRequest",A.DIf(),v,v,B.a9T,v,v)
u.L(1,"developerId",C.e3(),C.q("ht"))
return u})
w($,"MxH","w5u",()=>{var v=null,u=C.A("ContactPreferences",A.mGg(),v,v,B.a9T,v,v)
u.L(1,"developerId",C.e3(),C.q("ht"))
u.ao(2,"subtopicPreferences",A.ukA(),x.A)
u.ac(3,"contactEmailAddress")
return u})
w($,"Q9r","zdy",()=>{var v=null,u=C.A("SubtopicPreferences.ChannelScope",A.nJE(),v,v,B.a9T,v,v)
u.ak(1,"scope",B.h4n,C.q("aZa"))
u.ic(2,"appIds",4102,C.q("bJ"))
return u})
w($,"Q9s","zdz",()=>{var v,u=null,t=C.A("SubtopicPreferences",A.ukA(),u,u,B.a9T,u,u)
t.ak(1,"subtopic",B.hhc,C.q("vm"))
t.aF(7,"signedUpToInbox")
t.aF(8,"signedUpToEmail")
v=x.h
t.L(10,"inboxScope",A.nJE(),v)
t.L(11,"emailScope",A.nJE(),v)
return t})
w($,"Pk7","ywp",()=>{var v=null
return C.eI(v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,D.bK,v)})})()};
(a=>{a["MJt0lkbipG1jSIbZFc6Fx8qHKuc="]=a.current})($__dart_deferred_initializers__);
//# sourceMappingURL=main.dart.js_4202.part.js.map
