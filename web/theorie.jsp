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


--%>

</body>
</html>
