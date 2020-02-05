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

------------------------------------------------------------------------------------------------------------------------

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

--%>

</body>
</html>
