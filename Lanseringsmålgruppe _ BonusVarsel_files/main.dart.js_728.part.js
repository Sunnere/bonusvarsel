((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var A,C,B={
t2b(d){var y,x,w,v,u,t,s=null,r='" contains invalid characters (starting with "'
if(d.length===0)A.ae(A.as(A.aO("Email address is empty.",s),s))
if(!C.p.a9(d,"@"))A.ae(A.as(A.aO('Email address does not contain "@": "'+d+'"',s),s))
if(C.p.dX(d,"@"))A.ae(A.as(A.aO('Email address local part is empty: "'+d+'"',s),s))
if(C.p.lD(d,"@"))A.ae(A.as(A.aO('Email address domain part is empty: "'+d+'"',s),s))
y=C.p.eo(d,"@")
x=C.p.cI(d,0,y)
w=$.wEB()
v=A.fy(x,w,"")
if(v.length!==0)A.ae(A.as(A.aO('Email local part "'+x+r+v+'"): "'+d+'"',s),s))
u=C.p.co(d,y+1)
y=$.wEA()
t=A.fy(u,y,"")
if(t.length!==0)A.ae(A.as(A.aO('Email domain part "'+u+r+t+'"): "'+d+'"',s),s))
if(C.p.dX(u,"."))A.ae(A.as(A.aO('Email domain part starts with a period: "'+d+'"',s),s))
if(C.p.lD(u,"."))A.ae(A.as(A.aO('Email domain part ends with a period: "'+d+'"',s),s))
y=$.wEz()
if(!y.b.test(d))A.ae(A.as(A.aO('Email address format is invalid (e.g., lacks TLD): "'+d+'"',s),s))
y=new B.aPk()
new B.jm_(d).$1(y)
return y.efU()},
bST:function bST(){},
jm_:function jm_(d){this.a=d},
dlM:function dlM(d){this.a=d},
aPk:function aPk(){this.b=this.a=null}}
A=c[0]
C=c[2]
B=a.updateHolder(c[1452],B)
B.bST.prototype={
a1(d){return this.a},
$ial:1}
B.dlM.prototype={
ab(d,e){if(e==null)return!1
if(e===this)return!0
return e instanceof B.dlM&&this.a===e.a},
gal(d){return A.cl(A.a6(0,C.p.gal(this.a)))},
ga5(d){return this.a}}
B.aPk.prototype={
ga5(d){return this.gbfz().b},
gbfz(){var y=this,x=y.a
if(x!=null){y.b=x.a
y.a=null}return y},
efU(){var y=this.a
return this.a=y==null?new B.dlM(A.aN(this.gbfz().b,"EmailAddress","value")):y},
$iaL:1}
var z=a.updateTypes(["~(aPk)"])
B.jm_.prototype={
$1(d){d.gbfz().b=this.a
return d},
$S:z+0};(function inheritance(){var y=a.inheritMany,x=a.inherit
y(A.B,[B.bST,B.aPk])
x(B.jm_,A.aK)
x(B.dlM,B.bST)})()
A.ak(b.typeUniverse,JSON.parse('{"bST":{"al":["bST","aPk"]},"aPk":{"aL":["bST","aPk"]},"dlM":{"al":["bST","aPk"]}}'));(function lazyInitializers(){var y=a.lazyFinal
y($,"Ncd","wEz",()=>A.eh("^[a-zA-Z0-9.!#$%&'*+\\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$",!0,!1,!1))
y($,"Ncf","wEB",()=>A.eh("^[a-zA-Z0-9.!#$%&'*+\\/=?^_`{|}~-]+",!0,!1,!1))
y($,"Nce","wEA",()=>A.eh("^[a-zA-Z0-9-.]+",!0,!1,!1))})()};
(a=>{a["7SAWGbqndZUyy+1i7OnNXK6Q5Eo="]=a.current})($__dart_deferred_initializers__);
//# sourceMappingURL=main.dart.js_728.part.js.map
