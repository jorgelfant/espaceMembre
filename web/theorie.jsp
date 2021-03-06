<%--
  Created by IntelliJ IDEA.
  User: jorge.carrillo
  Date: 2/5/2020
  Time: 1:05 PM
  To change this template use File | Settings | File Templates.
--%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<html>
<head>
    <title>Title</title>
</head>
<body>

<%--
************************************************************************************************************************
                                  Le filtre : créez un espace membre
************************************************************************************************************************

Maintenant que nous savons manipuler les sessions et connecter nos utilisateurs, il serait intéressant de pouvoir
mettre en place un espace membre dans notre application : c'est un ensemble de pages web qui est uniquement accessible
aux utilisateurs connectés.

Pour ce faire, nous allons commencer par étudier le principe sur une seule page, via une servlet classique. Puis nous
allons étendre ce système à tout un ensemble de pages, et découvrir un nouveau composant, cousin de la servlet :

                                             le filtre !

************************************************************************************************************************
                                      Restreindre l'accès à une page
************************************************************************************************************************

Ce principe est massivement utilisé dans la plupart des applications web : les utilisateurs enregistrés et connectés
à un site ont bien souvent accès à plus de contenu et de fonctionnalités que les simples visiteurs.

Comment mettre en place une telle restriction d'accès ?

Jusqu'à présent, nous avons pris l'habitude de placer toutes nos JSP sous le répertoire /WEB-INF, et de les rendre
accessibles à travers des servlets. Nous savons donc que chaque requête qui leur est adressée passe d'abord par une
servlet. Ainsi pour limiter l'accès à une page donnée, la première intuition qui nous vient à l'esprit, c'est de nous
servir de la servlet qui lui est associée pour effectuer un test sur le contenu de la session, afin de vérifier si le
client est déjà connecté ou non.

Les pages d'exemple
*******************

Mettons en place pour commencer deux pages JSP :

      * une dont nous allons plus tard restreindre l'accès aux utilisateurs connectés uniquement, nommée
        accesRestreint.jsp et placée sous /WEB-INF ;

      * une qui sera accessible à tous les visiteurs, nommée accesPublic.jsp et placée sous la racine du projet
        (symbolisée par le dossier WebContent sous Eclipse).

Le contenu de ces pages importe peu, voici l'exemple basique que je vous propose :
*********************************************************************************
                      -----------------------------------------------------------
                      <%@ page pageEncoding="UTF-8" %>
                      <!DOCTYPE html>
                      <html>
                          <head>
                              <meta charset="utf-8" />
                              <title>Accès restreint</title>
                          </head>
                          <body>
                              <p>Vous êtes connecté(e) avec l'adresse ${sessionScope.sessionUtilisateur.email},
                                 vous avez bien accès à l'espace restreint.</p>
                          </body>
                      </html>
                      -----------------------------------------------------------

Reprenez alors la page accesPublic.jsp créée dans le chapitre précédent et modifiez son code ainsi :
****************************************************************************************************

                    <%@ page pageEncoding="UTF-8" %>
                    <!DOCTYPE html>
                    <html>
                        <head>
                            <meta charset="utf-8" />
                            <title>Accès public</title>
                        </head>
                        <body>
                            <p>Vous n'avez pas accès à l'espace restreint :
                               vous devez vous <a href="connexion">connecter</a> d'abord. </p>
                        </body>
                    </html>


Rien de particulier à signaler ici, si ce n'est l'utilisation d'une expression EL dans la page restreinte, afin
d'accéder à l'adresse mail de l'utilisateur enregistré en session, à travers l'objet implicite sessionScope.

************************************************************************************************************************
                                           La servlet de contrôle
************************************************************************************************************************

Ce qu'il nous faut réaliser maintenant, c'est ce fameux contrôle sur le contenu de la session avant d'autoriser
l'accès à la page accesRestreint.jsp. Voyez plutôt :

          public class Restriction extends HttpServlet {
              public static final String ACCES_PUBLIC     = "/accesPublic.jsp";
              public static final String ACCES_RESTREINT  = "/WEB-INF/accesRestreint.jsp";
              public static final String ATT_SESSION_USER = "sessionUtilisateur";

              public void doGet( HttpServletRequest request, HttpServletResponse response ) throws ServletException, IOException {
        /* Récupération de la session depuis la requête */
                  HttpSession session = request.getSession();

        /* Si l'objet utilisateur n'existe pas dans la session en cours, alors  l'utilisateur n'est pas connecté.*/
                  if ( session.getAttribute( ATT_SESSION_USER ) == null ) {
                      /* Redirection vers la page publique */
                      response.sendRedirect( request.getContextPath() + ACCES_PUBLIC );
                  } else {
                      /* Affichage de la page restreinte */
                      this.getServletContext().getRequestDispatcher( ACCES_RESTREINT ).forward( request, response );
                  }
              }
          }

************************************************************************************************************************

Comme vous le voyez, le procédé est très simple : il suffit de récupérer la session, de tester si l'attribut
sessionUtilisateur y existe déjà, et de rediriger vers la page restreinte ou publique selon le résultat du test.

Remarquez au passage l'emploi d'une redirection dans le cas de la page publique, et d'un forwarding dans le cas de
la page privée. Vous devez maintenant être familiers avec le principe, je vous l'ai expliqué dans le chapitre précédent.
Ici, si je mettais en place un forwarding vers la page publique au lieu d'une redirection HTTP, alors l'URL dans le
navigateur d'un utilisateur non connecté ne changerait pas lorsqu'il échoue à accéder à la page restreinte. Autrement dit,
il serait redirigé vers la page publique de manière transparente, et l'URL de son navigateur lui suggèrerait donc qu'il
se trouve sur la page restreinte, ce qui n'est évidemment pas le cas.

Par ailleurs, vous devez également prêter attention à la manière dont j'ai construit l'URL utilisée pour la redirection,
à la ligne 26. Vous êtes déjà au courant que, contrairement au forwarding qui est limité aux pages internes, la
redirection HTTP permet d'envoyer la requête à n'importe quelle page, y compris des pages provenant d'autres sites.
Ce que vous ne savez pas encore, à moins d'avoir lu attentivement les documentations des méthodes getRequestDispatcher()
et sendRedirect(), c'est que l'URL prise en argument par la méthode de forwarding est relative au contexte de
l'application, alors que l'URL prise en argument par la méthode de redirection est relative à la racine de l'application !

************************************************************************************************************************
                                 Concrètement, qu'est-ce que ça implique ?
************************************************************************************************************************

Cette différence est très importante :
**************************************

l'URL passée à la méthode getRequestDispatcher() doit être interne à l'application. En l’occurrence, dans notre projet
cela signifie qu'il est impossible de préciser une URL qui cible une page en dehors du projet pro. Ainsi, un appel à
getRequestDispatcher( "/accesPublic.jsp" ) ciblera automatiquement la page /pro/accesPublic.jsp, vous n'avez pas à
préciser vous-mêmes le contexte /pro ;

   * l'URL passée à la méthode sendRedirect() peut être externe à l'application. Cela veut dire que vous devez
     manuellement spécifier l'application dans laquelle se trouve votre page, et non pas, faire comme avec la méthode
     de forwarding, dans laquelle par défaut toute URL est considérée comme étant interne à l'application. Cela signifie
     donc que nous devons préciser le contexte de l'application dans l'URL passée à sendRedirect(). En l'occurrence,
     nous devons lui dire que nous souhaitons joindre une page contenue dans le projet pro :

     plutôt que d'écrire en dur  /pro/accesPublic.jsp, et risquer de devoir manuellement modifier cette URL si nous
     changeons le nom du contexte du projet plus tard, nous utilisons ici un appel à request.getContextPath(), qui
     retourne automatiquement le contexte de l'application courante, c'est-à-dire /pro dans notre cas.

   * Bref, vous l'aurez compris, vous devez être attentifs aux méthodes que vous employez et à la manière dont elles vont
     gérer les URL que vous leur transmettez. Entre les URL absolues, les URL relatives à la racine de l'application, les
     URL relatives au contexte de l'application et les URL relatives au répertoire courant, il est parfois difficile de ne
     pas s'emmêler les crayons ! >_

Pour terminer, voici sa configuration dans le fichier web.xml de notre application :
************************************************************************************

                    <servlet>
                    	<servlet-name>Restriction</servlet-name>
                    	<servlet-class>com.sdzee.servlets.Restriction</servlet-class>
                    </servlet>

                    <servlet-mapping>
                    	<servlet-name>Restriction</servlet-name>
                    	<url-pattern>/restriction</url-pattern>
                    </servlet-mapping>

N'oubliez pas de redémarrer Tomcat pour que ces modifications soient prises en compte.
*************************************************************************************

Test du système
***************

Pour vérifier le bon fonctionnement de cet exemple d'accès restreint, suivez le scénario suivant :
--------------------------------------------------------------------------------------------------

    1) redémarrez Tomcat, afin de faire disparaître toute session qui serait encore active ;

    2) rendez-vous sur la page http://localhost:8080/pro/restriction, et constatez au passage la redirection
       (changement d'URL) ;

    3) cliquez alors sur le lien vers la page de connexion, entrez des informations valides et connectez-vous ;

    4) rendez-vous à nouveau sur la page http://localhost:8080/pro/restriction, et constatez au passage l'absence
       de redirection (l'URL ne change pas) ;

    5) allez maintenant sur la page http://localhost:8080/pro/deconnexion ;

    6) retournez une dernière fois sur la page http://localhost:8080/pro/restriction.

Sans grande surprise, le système fonctionne bien : nous devons être connectés pour accéder à la page dont l'accès
est restreint, sinon nous sommes redirigés vers la page publique.

************************************************************************************************************************
                                           Le problème
************************************************************************************************************************

Oui, parce qu'il y a un léger problème ! Dans cet exemple, nous nous sommes occupés de deux pages : une page privée,
une page publique. C'était rapide, simple et efficace. Maintenant si je vous demande d'étendre la restriction à 100
pages privées, comment comptez-vous vous y prendre ?

En l'état actuel de vos connaissances, vous n'avez pas d'autres moyens que de mettre en place un test sur le contenu
de la session dans chacune des 100 servlets contrôlant l'accès aux 100 pages privées. Vous vous doutez bien que ce
n'est absolument pas viable, et qu'il nous faut apprendre une autre méthode. La réponse à nos soucis s'appelle le
filtre, et nous allons le découvrir dans le paragraphe suivant.


************************************************************************************************************************
                                           LE PRINCIPE DU FILTRE
************************************************************************************************************************

Généralités
***********

************************
Qu'est-ce qu'un filtre ?
************************

Un filtre est un objet Java qui peut <<modifier les en-têtes et le contenu d'une requête ou d'une réponse>>. Il se
positionne avant la servlet, et intervient donc en amont dans le cycle de traitement d'une requête par le serveur.
Il peut être associé à une ou plusieurs servlets. Voici à la figure suivante un schéma représentant le cas où plusieurs
filtres seraient associés à notre servlet de connexion.

                                                    SERVEUR
                           **********************************************************************
            rêquete HTTP   |        |      |        |      |        |       |                   |
           ------------->  |        |  --> |        |  --> |        |  -->  |    Servlet        |
Client                     | filtre |      | filtre |      | filtre |       |  [ connexion ]    |
            reponse HTTP   |   1    |      |   2    |      |   n    |               |
           <-------------  |        |  <-- |        | <--  |        |  <--         \/
                           |        |      |        |      |        |      |       JSP          |
                                                                           |  [ connexion.jsp ] |

Vous pouvez d'ores et déjà remarquer sur cette illustration que les filtres peuvent intervenir à la fois sur la
requête entrante et sur la réponse émise, et qu'ils s'appliquent dans un ordre précis, en cascade.

************************************************************************************************************************
                            Quelle est la différence entre un filtre et une servlet ?
************************************************************************************************************************

Alors qu'un composant web comme la servlet est utilisé pour générer une réponse HTTP à envoyer au client, le filtre
ne crée habituellement pas de réponse ; il se contente généralement d'appliquer d'éventuelles modifications à la paire
requête / réponse existante. Voici une liste des actions les plus communes réalisables par un filtre :

    |* interroger une requête et agir en conséquence ;

    |* empêcher la paire requête / réponse d'être transmise plus loin, autrement dit bloquer son cheminement
    |  dans l'application ;

    |* modifier les en-têtes et le contenu de la requête courante ;

    |* modifier les en-têtes et le contenu de la réponse courante.

************************************************************************************************************************
                                       Quel est l'intérêt d'un filtre ?
************************************************************************************************************************

Le filtre offre 3 avantages majeurs, qui sont interdépendants :
---------------------------------------------------------------

     1) il permet de modifier de manière transparente un échange HTTP. En effet, il n'implique pas nécessairement la
        création d'une réponse, et peut se contenter de modifier la paire requête / réponse existante ;

     2) tout comme la servlet, il est défini par un mapping, et peut ainsi être appliqué à plusieurs requêtes ;
                                                                                           ------------------
     3) plusieurs filtres peuvent être appliqués en cascade à la même requête.

C'est la combinaison de ces trois propriétés qui fait du filtre un composant parfaitement adapté à tous les traitements
de masse, nécessitant d'être appliqués systématiquement à tout ou partie des pages d'une application. À titre d'exemple,
on peut citer les usages suivants : l'authentification des visiteurs, la génération de logs, la conversion d'images,
la compression de données ou encore le chiffrement de données.

************************************************************************************************************************
                                               Fonctionnement
************************************************************************************************************************

Regardons maintenant comment est construit un filtre. À l'instar de sa cousine la servlet, qui doit obligatoirement
implémenter l'interface Servlet, le filtre doit implémenter l'interface Filter. Mais cette fois, contrairement au cas
de la servlet qui peut par exemple hériter de HttpServlet, il n'existe ici pas de classe fille. Lorsque nous étudions
la documentation de l'interface, nous remarquons qu'elle est plutôt succincte, elle ne contient que trois définitions
de méthodes : init(), doFilter() et destroy().

Vous le savez, lorsqu'une classe Java implémente une interface, elle doit redéfinir chaque méthode présente dans cette
interface. Ainsi, voici le code de la structure à vide d'un filtre

------------------------------------------------------------------------------------------------------------------------
                    import java.io.IOException;

                    import javax.servlet.Filter;
                    import javax.servlet.FilterChain;
                    import javax.servlet.FilterConfig;
                    import javax.servlet.ServletException;
                    import javax.servlet.ServletRequest;
                    import javax.servlet.ServletResponse;

                    public class ExempleFilter implements Filter {
                        public void init( FilterConfig config ) throws ServletException {
                            // ...
                        }

                        public void doFilter( ServletRequest request, ServletResponse response, FilterChain chain ) throws IOException,
                                ServletException {
                            // ...
                        }

                        public void destroy() {
                            // ...
                        }
                    }
------------------------------------------------------------------------------------------------------------------------

Les méthodes init() et destroy() concernent le cycle de vie du filtre dans l'application. Nous allons y revenir en
aparté dans le paragraphe suivant. La méthode qui va contenir les traitements effectués par le filtre est donc doFilter().
Vous pouvez d'ailleurs le deviner en regardant les arguments qui lui sont transmis : elle reçoit en effet la requête et
la réponse, ainsi qu'un troisième élément, la chaîne des filtres.

***************************
À quoi sert cette chaîne ?
***************************

Elle vous est encore inconnue, mais elle est en réalité un objet relativement simple : je vous laisse jeter un œil à
sa courte documentation. Je vous ai annoncé un peu plus tôt que plusieurs filtres pouvaient être appliqués à la même
requête. Eh bien c'est à travers cette chaîne qu'un ordre va pouvoir être établi : chaque filtre qui doit être appliqué
à la requête va être inclus à la chaîne, qui ressemble en fin de compte à une file d'invocations.

Cette chaîne est entièrement gérée par le conteneur, vous n'avez pas à vous en soucier. La seule chose que vous allez
contrôler, c'est le passage d'un filtre à l'autre dans cette chaîne via l'appel de sa seule et unique méthode, elle
aussi nommée doFilter().

***********************************************************
Comment l'ordre des filtres dans la chaîne est-il établi ?
***********************************************************

Tout comme une servlet, un filtre doit être déclaré dans le fichier web.xml de l'application pour être reconnu :

                              -----------------------------------------------------------
                              <?xml version="1.0" encoding="UTF-8"?>
                              <web-app>
                                  ...

                                  <filter>
                                      <filter-name>Exemple</filter-name>
                                      <filter-class>package.ExempleFilter</filter-class>
                                  </filter>
                                  <filter>
                                      <filter-name>SecondExemple</filter-name>
                                      <filter-class>package.SecondExempleFilter</filter-class>
                                  </filter>

                                  <filter-mapping>
                                      <filter-name>Exemple</filter-name>
                                      <url-pattern>/*</url-pattern>
                                  </filter-mapping>
                                  <filter-mapping>
                                      <filter-name>SecondExemple</filter-name>
                                      <url-pattern>/page</url-pattern>
                                  </filter-mapping>

                                  ...
                              </web-app>

************************************************************************************************************************

Vous reconnaissez ici la structure des blocs utilisés pour déclarer une servlet, la seule différence réside dans le
nommage des champs : <servlet> devient <filter>, <servlet-name> devient <filter-name>, etc.

Eh bien là encore, de la même manière que pour les servlets, l'ordre des déclarations des mappings des filtres dans
le fichier est important : c'est cet ordre qui va être suivi lors de l'invocation de plusieurs filtres appliqués à
une même requête. En d'autres termes, c'est dans cet ordre que la chaîne des filtres va être automatiquement initialisée
par le conteneur. Ainsi, si vous souhaitez qu'un filtre soit appliqué avant un autre, placez son mapping avant le mapping
du second dans le fichier web.xml de votre application.

************************************************************************************************************************
                                                 Cycle de vie
************************************************************************************************************************

Avant de passer à l'application pratique et à la mise en place d'un filtre, penchons-nous un instant sur la manière
dont le conteneur le gère. Une fois n'est pas coutume, il y a là encore de fortes similitudes avec une servlet.
Lorsque l'application web démarre, le conteneur de servlets va créer une instance du filtre et la garder en mémoire
durant toute l'existence de l'application. La même instance va être réutilisée pour chaque requête entrante dont l'URL
correspond au contenu du champ <url-pattern> du mapping du filtre. Lors de l'instanciation, la méthode init() est
appelée par le conteneur : si vous souhaitez passer des paramètres d'initialisation au filtre, vous pouvez alors les
récupérer depuis l'objet FilterConfig passé en argument à la méthode.

Pour chacune de ces requêtes, la méthode doFilter() va être appelée. Ensuite c'est évidemment au développeur, à vous
donc, de décider quoi faire dans cette méthode : une fois vos traitements appliqués, soit vous appelez la méthode
doFilter() de l'objet FilterChain pour passer au filtre suivant dans la liste, soit vous effectuez une redirection ou
un forwarding pour changer la destination d'origine de la requête.

Enfin, je me répète mais il est possible de faire en sorte que plusieurs filtres s'appliquent à la même URL. Ils seront
alors appelés dans le même ordre que celui de leurs déclarations de mapping dans le fichier web.xml de l'application.

************************************************************************************************************************
                                Restreindre l'accès à un ensemble de pages
************************************************************************************************************************

Restreindre un répertoire
*************************

Après cette longue introduction plutôt abstraite, lançons-nous et essayons d'utiliser un filtre pour répondre à notre
problème : mettre en place une restriction d'accès sur un groupe de pages. C'est probablement l'utilisation la plus
classique du filtre dans une application web !

Dans notre cas, nous allons nous en servir pour vérifier la présence d'un utilisateur dans la session :
------------------------------------------------------------------------------------------------------

    * s'il est présent, notre filtre laissera la requête poursuivre son cheminement jusqu'à la page souhaitée ;

    * s'il n'existe pas, notre filtre redirigera l'utilisateur vers la page publique.

Pour cela, nous allons commencer par créer un répertoire nommé restreint que nous allons placer à la racine de
notre projet, dans lequel nous allons déplacer le fichier accesRestreint.jsp et y placer les deux fichiers suivants :

Voici à la figure suivante un aperçu de l’arborescence que vous devez alors obtenir:

repertoire restreint dans WEB avec :  accesRestreint.jsp   accesRestreint2.jsp   accesRestreint3.jsp
et accesPublic.jsp  dans WEB

************************************************************************************************************************

C'est de ce répertoire restreint que nous allons limiter l'accès aux utilisateurs connectés (accesRestreint) .
Souvenez-vous bien du point suivant : pour le moment, nos pages JSP n'étant pas situées sous le répertoire /WEB-INF,
elles sont accessibles au public directement depuis leurs URL respectives. Par exemple, vous pouvez vous rendre sur
http://localhost:8080/pro/restreint/accesRestreint.jsp même sans être connectés, le seul problème que vous rencontrerez
est l'absence de l'adresse email dans le message affiché.

Supprimez ensuite la servlet Restriction que nous avions développée en début de chapitre, ainsi que sa déclaration
dans le fichier web.xml : elle nous est dorénavant inutile.

                           JE LA GARDE ICI COMME SOUVENIR
 -----------------------------------------------------------------------------------------------------------------------
 public class Restriction extends HttpServlet {
       public static final String ACCES_PUBLIC = "/accesPublic.jsp";
       public static final String ACCES_RESTREINT = "/WEB-INF/accesRestreint.jsp";
       public static final String ATT_SESSION_USER = "sessionUtilisateur";

       public void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
           /* Récupération de la session depuis la requête */
           HttpSession session = request.getSession();

           /* Si l'objet utilisateur n'existe pas dans la session en cours, alors l'utilisateur n'est pas connecté.*/
           if (session.getAttribute(ATT_SESSION_USER) == null) {
               /* Redirection vers la page publique */
               response.sendRedirect(request.getContextPath() + ACCES_PUBLIC);
           } else {
               /* Affichage de la page restreinte */
               this.getServletContext().getRequestDispatcher(ACCES_RESTREINT).forward(request, response);
           }
       }
    }
------------------------------------------------------------------------------------------------------------------------

Nous pouvons maintenant créer notre filtre. Je vous propose de le placer dans un nouveau package com.sdzee.filters,
et de le nommer RestrictionFilter. Voyez à la figure suivante comment procéder après un Ctrl + N sous Eclipse.

************************************************************************************************************************

       public class RestrictionFilter implements Filter {

             // method de l'interface Filter 1
             public void init(FilterConfig filterConfig) throws ServletException {

             }

             // method de l'interface Filter 2
             public void doFilter(ServletRequest servletRequest, ServletResponse servletResponse, FilterChain filterChain)
                                                                                   throws IOException, ServletException {

             }

             // method de l'interface Filter 3
             public void destroy() {

             }
       }

************************************************************************************************************************
Rien de fondamental n'a changé par rapport à la version générée par Eclipse, j'ai simplement retiré les commentaires
et renommé les arguments des méthodes pour que le code de notre filtre soit plus lisible par la suite.

Comme vous le savez, c'est dans la méthode doFilter() que nous allons réaliser notre vérification. Puisque nous avons
déjà développé cette fonctionnalité dans une servlet en début de chapitre, il nous suffit de reprendre son code et de
l'adapter un peu :
------------------------------------------------------------------------------------------------------------------------
              public class RestrictionFilter implements Filter {
                  public static final String ACCES_PUBLIC     = "/accesPublic.jsp";
                  public static final String ATT_SESSION_USER = "sessionUtilisateur";

                  public void init( FilterConfig config ) throws ServletException {
                  }

                  public void doFilter( ServletRequest req, ServletResponse res, FilterChain chain ) throws IOException,
                          ServletException {
                      /* Cast des objets request et response */
                      HttpServletRequest request = (HttpServletRequest) req;
                      HttpServletResponse response = (HttpServletResponse) res;

                      /* Récupération de la session depuis la requête */
                      HttpSession session = request.getSession();

                      /**
                       * Si l'objet utilisateur n'existe pas dans la session en cours, alors
                       * l'utilisateur n'est pas connecté.
                       */
                      if ( session.getAttribute( ATT_SESSION_USER ) == null ) {
                          /* Redirection vers la page publique */
                          response.sendRedirect( request.getContextPath() + ACCES_PUBLIC );
                      } else {
                          /* Affichage de la page restreinte */
                          chain.doFilter( request, response );
                      }
                  }

                  public void destroy() {
                  }
              }
------------------------------------------------------------------------------------------------------------------------

************************************************************************************************************************
                                            Quelques explications s'imposent.
************************************************************************************************************************

Aux lignes 25 et 26, vous constatez que nous convertissons les objets transmis en arguments à notre méthode doFilter().
La raison en est simple : comme je vous l'ai déjà dit, il n'existe pas de classe fille implémentant l'interface Filter,
alors que côté servlet nous avons bien HttpServlet qui implémente Servlet. Ce qui signifie que notre filtre n'est pas
spécialisé, il implémente uniquement Filter et peut traiter n'importe quel type de requête et pas seulement les
requêtes HTTP.

C'est donc pour cela que nous devons manuellement spécialiser nos objets, en effectuant un cast vers
les objets dédiés aux requêtes et réponses HTTP : c'est seulement en procédant à cette conversion que nous aurons accès
ensuite à la session, qui est propre à l'objet HttpServletRequest, et n'existe pas dans l'objet ServletRequest.

À la ligne 40, nous avons remplacé le forwarding auparavant en place dans notre servlet par un appel à la méthode
<<< doFilter() >>> de l'objet FilterChain. Celle-ci a en effet une particularité intéressante : si un autre filtre existe
après le filtre courant dans la chaîne, alors c'est vers ce filtre que la requête va être transmise. Par contre,
si aucun autre filtre n'est présent ou si le filtre courant est le dernier de la chaîne, alors c'est vers la ressource
initialement demandée que la requête va être acheminée. En l'occurrence, nous n'avons qu'un seul filtre en place, notre
requête sera donc logiquement transmise à la page demandée.

Pour mettre en scène notre filtre, il nous faut enfin le déclarer dans le fichier web.xml de notre application :
------------------------------------------------------------------------------------------------------------------------

                               <filter>
                               	<filter-name>RestrictionFilter</filter-name>
                               	<filter-class>com.sdzee.filters.RestrictionFilter</filter-class>
                               </filter>
                               <filter-mapping>
                               	<filter-name>RestrictionFilter</filter-name>
                               	<url-pattern>/restreint/*</url-pattern>
                               </filter-mapping>

------------------------------------------------------------------------------------------------------------------------
À la ligne 9, vous pouvez remarquer l'url-pattern précisé : le caractère * signifie que notre filtre va être appliqué
à toutes les pages présentes sous le répertoire /restreint.

Redémarrez ensuite Tomcat pour que les modifications effectuées soient prises en compte, puis suivez ce scénario de
tests :

       1) essayez d'accéder à la page http://localhost:8080/pro/restreint/accesRestreint.jsp, et constatez la
          redirection vers la page publique ;

       2) rendez-vous sur la page de connexion et connectez-vous avec des informations valides ;

       3) essayez à nouveau d'accéder à la page http://localhost:8080/pro/restreint/accesRestreint.jsp, et constatez
          le succès de l'opération ;

       4) essayez alors d'accéder aux pages accesRestreint2.jsp et accesRestreint3.jsp, et constatez là encore le
          succès de l'opération ;

       5) rendez-vous sur la page de déconnexion ;

       6) puis tentez alors d'accéder à la page http://localhost:8080/pro/restreint/accesRestreint.jsp et constatez
          cette fois l'échec de l'opération.


Notre problème est bel et bien réglé ! Nous sommes maintenant capables de bloquer l'accès à un ensemble de pages avec
une simple vérification dans un unique filtre : nous n'avons pas besoin de dupliquer le contrôle effectué dans des
servlets appliquées à chacune des pages !

************************************************************************************************************************
                                    Restreindre l'application entière
************************************************************************************************************************

Avant de nous quitter, regardons brièvement comment forcer l'utilisateur à se connecter pour accéder à notre application.
Ce principe est par exemple souvent utilisé sur les intranets d'entreprise, où la connexion est généralement obligatoire
dès l'entrée sur le site.

La première chose à faire, c'est de modifier la portée d'application du filtre. Puisque nous souhaitons couvrir
l'intégralité des requêtes entrantes, il suffit d'utiliser le caractère * appliqué à la racine. La déclaration de
notre filtre devient donc :

------------------------------------------------------------------------------------------------------------------------
                           <filter>
                                   <filter-name>RestrictionFilter</filter-name>
                                   <filter-class>com.sdzee.filters.RestrictionFilter</filter-class>
                           </filter>
                           <filter-mapping>
                                   <filter-name>RestrictionFilter</filter-name>
                                   <url-pattern>/*</url-pattern>
                           </filter-mapping>
------------------------------------------------------------------------------------------------------------------------

Redémarrez Tomcat pour que la modification soit prise en compte.
----------------------------------------------------------------

Maintenant, vous devez réfléchir à ce que nous venons de mettre en place : nous avons ordonné à notre filtre de bloquer
toutes les requêtes entrantes si l'utilisateur n'est pas connecté. Le problème, c'est que si nous ne changeons pas le
code de notre filtre, alors l'utilisateur ne pourra jamais accéder à notre site !

Pourquoi ? Notre filtre le redirigera vers la page accesPublic.jsp comme il le faisait dans le cas de la restriction
d'accès au répertoire restreint, non ?

Eh bien non, plus maintenant ! La méthode de redirection que nous avons mise en place va bien être appelée, mais comme
vous le savez elle va déclencher un échange HTTP, c'est-à-dire un aller-retour avec le navigateur du client. Le client
va donc renvoyer automatiquement une requête, qui va à son tour être interceptée par notre filtre. Le client n'étant
toujours pas connecté, le même phénomène va se reproduire, etc. Si vous y tenez, vous pouvez essayer : vous verrez alors
votre navigateur vous avertir que la page que vous essayez de contacter pose problème. Voici aux figures suivantes les
messages affichés respectivement par Chrome et Firefox.

                                              Échec de la restriction

************************
La solution est simple :
************************

     1) il faut envoyer l'utilisateur vers la page de connexion, et non plus vers la page accesPublic.jsp ;

     2) il faut effectuer non plus une redirection HTTP mais un forwarding, afin qu'aucun nouvel échange HTTP n'ait
        lieu et que la demande aboutisse.

Voici ce que devient le code de notre filtre, les changements intervenant aux lignes 16 et 37 :

                         public class RestrictionFilter implements Filter {
                             public static final String ACCES_CONNEXION  = "/connexion"; //linea agragada
                             public static final String ATT_SESSION_USER = "sessionUtilisateur";

                             public void init( FilterConfig config ) throws ServletException {
                             }

                             public void doFilter( ServletRequest req, ServletResponse res, FilterChain chain ) throws IOException,
                                     ServletException {
                                 /* Cast des objets request et response */
                                 HttpServletRequest request = (HttpServletRequest) req;
                                 HttpServletResponse response = (HttpServletResponse) res;

                                 /* Récupération de la session depuis la requête */
                                 HttpSession session = request.getSession();

                                 /**
                                  * Si l'objet utilisateur n'existe pas dans la session en cours, alors
                                  * l'utilisateur n'est pas connecté.
                                  */
                                 if ( session.getAttribute( ATT_SESSION_USER ) == null ) {
                                     /* Redirection vers la page publique */
                                     request.getRequestDispatcher( ACCES_CONNEXION ).forward( request, response );
                                 } else {
                                     /* Affichage de la page restreinte */
                                     chain.doFilter( request, response );
                                 }
                             }

                             public void destroy() {
                             }
                         }

C'est tout pour le moment. Tentez alors d'accéder à la page http://localhost:8080/pro/restreint/accesRestreint.jsp,
vous obtiendrez le formulaire affiché à la figure suivante.

                                  -------------
                                  Ratage du CSS
                                  -------------

Vous pouvez alors constater que notre solution fonctionne : l'utilisateur est maintenant bien redirigé vers la page
de connexion. Oui, mais...

---------------------------------------
Où est passé le design de notre page ?!
---------------------------------------

Eh bien la réponse est simple : il a été bloqué !
                                -----------------
En réalité lorsque vous accédez à une page web sur laquelle est attachée une feuille de style CSS, votre navigateur va,
dans les coulisses, envoyer une deuxième requête au serveur pour récupérer silencieusement cette feuille et ensuite
appliquer les styles au contenu HTML. Et vous pouvez le deviner, cette seconde requête a bien évidemment été bloquée
par notre superfiltre !

************************************************************************************************************************
                   Il y a plusieurs solutions envisageables. Voici les deux plus courantes :
************************************************************************************************************************

   1) ne plus appliquer le filtre à la racine de l'application, mais seulement sur des répertoires ou pages en particulier,
      en prenant soin d'éviter de restreindre l'accès à notre page CSS ;

   2) continuer à appliquer le filtre sur toute l'application, mais déplacer notre feuille de style dans un répertoire,
      et ajouter un passe-droit au sein de la méthode doFilter() du filtre.
         -----------------------------------------------------------------

Je vais vous expliquer cette seconde méthode. Une bonne pratique d'organisation consiste en effet à placer sous un
répertoire commun toutes les ressources destinées à être incluses, afin de permettre un traitement simplifié.
Par "ressources incluses", on entend généralement les feuilles de style CSS, les feuilles Javascript ou encore les
images, bref tout ce qui est susceptible d'être inclus dans une page HTML ou une page JSP.

Pour commencer, créez donc un répertoire nommé inc sous la racine de votre application et placez-y le fichier CSS,
comme indiqué à la figure suivante.

Puisque nous venons de déplacer le fichier, nous devons également modifier son appel dans la page de connexion :
----------------------------------------------------------------------------------------------------------------

                     <!-- Dans le fichier connexion.jsp, remplacez l'appel suivant : -->
                     <link type="text/css" rel="stylesheet" href="form.css" />

                     <!-- Par celui-ci : -->
                     <link type="text/css" rel="stylesheet" href="inc/form.css" />
-----------------------------------------------------------------------------------------------------------------

Pour terminer, nous devons réaliser dans la méthode doFilter() de notre filtre ce fameux passe-droit sur
le dossier inc :

On rajoute ceci dans la methode filter :

En gros request.getRequestURI() me retourne toute l'url, aceci je lui applique un substring, et cela
commencera a conter l'url à partir du length du context c'est à dire qu'il contiendra l'url qu'à partir de
/inc    cad du slash    on serait tenté de créer un dossier pareil pour images et js et lui rajoutes
avec un else if pour le laisses passer à chaque fois un html/jsp associé essaie de les récupérer

    /* Non-filtrage des ressources statiques */                       25
        String chemin = request.getRequestURI().substring( request.getContextPath().length() );
        if ( chemin.startsWith( "/inc" ) ) {
            chain.doFilter( request, response );
            return;
        }
------------------------------------------------------------------------------------------------------------------------

Explications :

     * à la ligne 29, nous récupérons l'URL d'appel de la requête HTTP via la méthode getRequestURI(), puis nous plaçons
       dans la chaîne chemin sa partie finale, c'est-à-dire la partie située après le contexte de l'application.
       Typiquement, dans notre cas si nous nous rendons sur http://localhost:8080/pro/restreint/accesRestreint.jsp,
       la méthode getRequestURI() va renvoyer /pro/restreint/accesRestreint.jsp et chemin va contenir
       uniquement /restreint/accesRestreint.jsp ;

     * à la ligne 30, nous testons si cette chaîne chemin commence par /inc : si c'est le cas, cela signifie que la
       page demandée est une des ressources statiques que nous avons placées sous le répertoire inc, et qu'il ne faut
       donc pas lui appliquer le filtre !

     * à la ligne 31, nous laissons la requête poursuivre son cheminement en appelant la méthode doFilter() de la chaîne.

------------------------------------------------------------------------------------------------------------------------

Faites les modifications, enregistrez et tentez d'accéder à la page http://localhost:8080/pro/connexion. Observez la
figure suivante.

Le résultat est parfait, ça fonctionne ! Oui, mais...

Quoi encore ? Il n'y a plus de problème, toute l'application fonctionne maintenant !

Toute ? Non ! Un irréductible souci résiste encore et toujours... Par exemple, rendez-vous maintenant
sur la page http://localhost:8080/pro/restreint/accesRestreint.jsp.

************************************************************************************************************************
Pourquoi la feuille de style n'est-elle pas appliquée à notre formulaire de connexion dans ce cas ?
************************************************************************************************************************

Eh bien cette fois, c'est à cause du forwarding que nous avons mis en place dans notre filtre ! Eh oui, souvenez-vous :
le forwarding ne modifie pas l'URL côté client, comme vous pouvez d'ailleurs le voir dans votre dernière fenêtre.

Cela veut dire que le NAVIGATEUR du client reçoit bien le formulaire de connexion, mais ne sait pas que c'est la page
/connexion.jsp qui le lui a renvoyé, il croit qu'il s'agit tout bonnement du retour de la page demandée, c'est-à-dire
/restreint/accesRestreint.jsp.

De ce fait, lorsqu'il va silencieusement envoyer une requête au serveur pour récupérer la feuille CSS associée à la
page de connexion, le navigateur va naïvement se baser sur l'URL qu'il a en mémoire pour interpréter l'appel suivant :

                      <link type="text/css" rel="stylesheet" href="inc/form.css" />
                      -------------------------------------------------------------

En conséquence, il va considérer que l'URL relative "inc/form.css" se rapporte au répertoire qu'il pense être le
répertoire courant, à savoir /restreint (puisque pour lui, le formulaire a été affiché par /restreint/accesRestreint.jsp).
Ainsi, le navigateur va demander au serveur de lui renvoyer la page /restreint/inc/forms.css, alors que cette page
n'existe pas ! Voilà pourquoi le design de notre formulaire semble avoir disparu.

Pour régler ce problème, nous n'allons ni toucher au filtre ni au forwarding, mais nous allons tirer parti de la JSTL
pour modifier la page connexion.jsp :

                     -------------------------------------------------------------------
                     <!-- Dans le fichier connexion.jsp, remplacez l'appel suivant : -->
                     <link type="text/css" rel="stylesheet" href="inc/form.css" />

                     <!-- Par celui-ci : -->
                     <link type="text/css" rel="stylesheet" href="<c:url value="/inc/form.css"/>" />
------------------------------------------------------------------------------------------------------------------------

Vous vous souvenez de ce que je vous avais expliqué à propos de la balise <c:url> ? Je vous avais dit qu'elle ajoutait
automatiquement le contexte de l'application aux URL absolues qu'elle contenait. C'est exactement ce que nous souhaitons :
dans ce cas, le rendu de la balise sera /pro/inc/form.css. Le navigateur reconnaîtra ici une URL absolue et non plus
une URL relative comme c'était le cas auparavant, et il réalisera correctement l'appel au fichier CSS !

Dans ce cas, pourquoi ne pas avoir directement écrit l'URL absolue "/pro/inc/form.css" dans l'appel ? Pourquoi
s'embêter avec <c:url> ?

Pour la même raison que nous avions utilisé request.getContextPath() dans la servlet que nous avions développée
en première partie de ce chapitre. Si demain nous décidons de changer le nom du contexte, notre page fonctionnera
toujours avec la balise <c:url>, alors qu'il faudra éditer et modifier l'URL absolue entrée à la main sinon.
J'espère que cette fois, vous avez bien compris ! ;)

Une fois la modification effectuée, voici le résultat (voir la figure suivante).

Finalement, nous y sommes : tout fonctionne comme prévu !

------------------------------------------------------------------------------------------------------------------------
Si je vous fais mettre en place une telle restriction, c'est uniquement pour vous faire découvrir le principe.
Dans une vraie application, il faudra bien prendre garde à ne pas restreindre des pages dont l'accès est supposé
être libre !
------------------------------------------------------------------------------------------------------------------------

Par exemple, dans votre projet il est dorénavant impossible pour un utilisateur de s'inscrire ! Eh oui, réflechissez-bien :
puisque le filtre est en place, dès lors qu'un utilisateur non inscrit (et donc non connecté) tente d'accéder à la page
d'inscription, il est automatiquement redirigé vers la page de connexion ! Devoir se connecter avant même de pouvoir
s'inscrire, admettez qu'on a connu plus logique... :-° Pour régler le problème, il suffirait en l'occurrence d'ajouter
une exception au filtre pour autoriser l'accès à la page d'inscription, tout comme nous l'avons fait pour le dossier
/inc. Mais ce n'est pas sur cette correction en particulier que je souhaite insister, vous devez surtout bien réaliser
que lorsque vous appliquez des filtres avec un spectre très large, voire intégral, alors vous devez faire très attention
et bien réfléchir à tous les cas d'utilisation de votre application.

************************************************************************************************************************
                                         Désactiver le filtre
************************************************************************************************************************

Une fois vos développements et tests terminés, pour plus de commodité dans les exemples à suivre, je vous conseille
de désactiver ce filtre. Pour cela, commentez simplement sa déclaration dans le fichier web.xml de votre application :

Il faudra redémarrer Tomcat pour que la modification soit prise en compte.

************************************************************************************************************************
                                      Modifier le mode de déclenchement d'un filtre
************************************************************************************************************************

Je vous ai implicitement fait comprendre à travers ces quelques exemples qu'un filtre était déclenché lors de la
réception d'une requête HTTP uniquement. Eh bien sachez qu'il s'agit là d'un comportement par défaut ! En réalité,
un filtre est tout à fait capable de s'appliquer à un forwarding, mais il faut pour cela modifier sa déclaration dans
le fichier web.xml :
                             ----------------------------------------------------------------------
                              <filter>
                                  <filter-name>RestrictionFilter</filter-name>
                                  <filter-class>com.sdzee.filters.RestrictionFilter</filter-class>
                              </filter>
                              <filter-mapping>
                                  <filter-name>RestrictionFilter</filter-name>
                                  <url-pattern>/*</url-pattern>
                                  <dispatcher>REQUEST</dispatcher>
                                  <dispatcher>FORWARD</dispatcher>
                              </filter-mapping>
                             ----------------------------------------------------------------------

Il suffit, comme vous pouvez l'observer, de rajouter un champ <dispatcher> à la fin de la section <filter-mapping>.

De même, si dans votre projet vous mettez en place des inclusions et souhaitez leur appliquer un filtre, alors il
faudra ajouter cette ligne à la déclaration du filtre :

                             <dispatcher>INCLUDE</dispatcher>

Nous n'allons pas nous amuser à vérifier le bon fonctionnement de ces changements. Retenez simplement qu'il est bel
et bien possible de filtrer les forwardings et inclusions en plus des requêtes directes entrantes, en modifiant au
cas par cas les déclarations des filtres à appliquer. Enfin, n'oubliez pas que ces ajouts au fichier web.xml ne sont
pris en compte qu'après un redémarrage du serveur.

************************************************************************************************************************
                                      Retour sur l'encodage UTF-8
************************************************************************************************************************

Avant de passer à la suite, je souhaite vous faire découvrir un autre exemple d'utilisation d'un filtre. Vous ne l'avez
peut-être pas encore remarqué, mais notre application ne sait toujours pas correctement gérer les caractères accentués,
ni les caractères spéciaux et alphabets non latins...

Comment est-ce possible ? Nous avons déjà paramétré Eclipse et notre projet pour que tous nos fichiers soient encodés
en UTF-8, il ne devrait plus y avoir de problème !

Je vous ai déjà expliqué, lorsque nous avons associé notre première servlet à une page JSP, que les problématiques
d'encodage intervenaient à deux niveaux : côté navigateur et côté serveur. Eh bien en réalité, ce n'est pas si simple.
Avec ce que nous avons mis en place, le navigateur est bien capable de déterminer l'encodage des données envoyées par
le serveur, mais le serveur quant à lui est incapable de déterminer l'encodage des données envoyées par le client, lors
d'une requête GET ou POST. Essayez dans votre formulaire d'inscription d'entrer un nom qui contient un accent, par
exemple (voir la figure suivante).

nom : cèpe

Si vous cliquez alors sur le bouton d'inscription, votre navigateur va envoyer une requête POST au serveur, qui va
alors retourner le résultat affiché à la figure suivante.

cA ..pe

Vous devez ici reconnaître le problème que nous avions rencontrés à nos débuts ! Là encore, il s'agit d'une erreur
d'interprétation : le serveur considère par défaut que les données qui lui sont transmises suivent l'encodage
latin ISO-8859-1, alors qu'en réalité ce sont des données en UTF-8 qui sont envoyées, d'où les symboles bizarroïdes
à nouveau observés...

Très bien, mais quel est le rapport avec nos filtres ?

Pour corriger ce comportement, il est nécessaire d'effectuer un appel à la méthode setCharacterEncoding() non plus
depuis l'objet HttpServletResponse comme nous l'avions fait dans notre toute première servlet, mais depuis l'objet
HttpServletRequest ! En effet, nous cherchons bien ici à préciser l'encodage des données de nos requêtes ; nous
l'avons déjà appris, l'encodage des données de nos réponses est quant à lui assuré par la ligne placée en tête de
chacune de nos pages JSP.

Ainsi, nous pourrions manuellement ajouter une ligne request.setCharacterEncoding("UTF-8"); dans les méthodes doPost()
de chacune de nos servlets, mais nous savons que dupliquer cet appel dans toutes nos servlets n'est pas pratique du tout.
En outre, la documentation de la méthode précise qu'il faut absolument réaliser l'appel avant toute lecture de données,
afin que l'encodage soit bien pris en compte par le serveur.

Voilà donc deux raisons parfaites pour mettre en place... un filtre ! C'est l'endroit idéal pour effectuer simplement
cet appel à chaque requête reçue, et sur l'intégralité de l'application. Et puisque qu'une bonne nouvelle n'arrive jamais
seule, il se trouve que nous n'avons même pas besoin de créer nous-mêmes ce filtre, Tomcat en propose déjà un nativement !
Il va donc nous suffire d'ajouter une déclaration dans le fichier web.xml de notre application pour que notre projet soit
enfin capable de gérer correctement les requêtes POST qu'il traite :

                           ---------------------------------------------------------------------
                           <filter>
                               <filter-name>Set Character Encoding</filter-name>
                               <filter-class>org.apache.catalina.filters.SetCharacterEncodingFilter</filter-class>
                               <init-param>
                                   <param-name>encoding</param-name>
                                   <param-value>UTF-8</param-value>
                               </init-param>
                               <init-param>
                                   <param-name>ignore</param-name>
                                   <param-value>false</param-value>
                               </init-param>
                           </filter>
                           <filter-mapping>
                               <filter-name>Set Character Encoding</filter-name>
                               <url-pattern>/*</url-pattern>
                           </filter-mapping>
                           --------------------------------------------------------------------------

Vous retrouvez la déclaration que vous avez apprise un peu plus tôt, via la balise <filter>. La seule nouveauté,
c'est l'utilisation du filtre natif SetCharacterEncodingFilter issu du package org.apache.catalina.filters. Comme
vous pouvez le constater, celui-ci nécessite deux paramètres d’initialisation dont un nommé encoding, qui permet au
développeur de spécifier l'encodage à utiliser. Je vous laisse parcourir la documentation du filtre pour plus
d'informations. ;)

De même, vous retrouvez dans la section <filter-mapping> l'application du filtre au projet entier, grâce au
caractère * appliqué à la racine.

Une fois les modifications effectuées, il vous suffit alors de redémarrer Tomcat et d'essayer à nouveau de saisir
un nom accentué.

Vous remarquez cette fois la bonne gestion du mot accentué, qui est ré-affiché correctement. Bien évidemment,
cela vaut également pour tout caractère issu d'un alphabet non latin : votre application est désormais capable de
traiter des données écrites en arabe, en chinois, en russe, etc.

************************************************************************************************************************

   * Le forwarding s'effectue sur le serveur de manière transparente pour le client, alors que la redirection implique
     un aller/retour chez le client.

   * Un filtre ressemble à une servlet en de nombreux aspects :

           - il agit sur le couple requête / réponse initié par le conteneur de servlets ;

           - il se déclare dans le fichier web.xml via deux sections <filter> et <filter-mapping> ;

           - il contient une méthode de traitement, nommée doFilter() ;

           - il peut s'appliquer à un pattern d'URL comme à une page en particulier.

   * Plusieurs filtres sont applicables en cascade sur une même paire requête / réponse, dans l'ordre défini par
     leur déclaration dans le web.xml.

   * La transition d'un filtre vers le maillon suivant de la chaîne s'effectue via un appel à la méthode doFilter()
     de l'objet FilterChain.

--%>

</body>
</html>
