package com.exemple.filters;

import javax.servlet.Filter;
import javax.servlet.FilterConfig;
import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;


public class RestrictionFilter implements Filter {
    public static final String ACCES_CONNEXION = "/connexion";
    //public static final String ACCES_PUBLIC = "/accesPublic.jsp";
    public static final String ATT_SESSION_USER = "sessionUtilisateur";

    //--------------------------------- method de l'interface Filter 1 -------------------------------------------------
    public void init(FilterConfig config) throws ServletException {

    }
    //--------------------------------- method de l'interface Filter 2 -------------------------------------------------

    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain) throws IOException, ServletException {
        // Cast des objets request et response
        HttpServletRequest request = (HttpServletRequest) req;
        HttpServletResponse response = (HttpServletResponse) res;

        // Non-filtrage des ressources statiques -- PASSE-DROIT pour les fichiers associés à nos html (ex: css, js, images)
        String chemin = request.getRequestURI().substring(request.getContextPath().length());
        if (chemin.startsWith("/inc")) {
            chain.doFilter(request, response);
            return;
        }

        // Récupération de la session depuis la requête
        HttpSession session = request.getSession();

        // Si l'objet utilisateur n'existe pas dans la session en cours, alors l'utilisateur n'est pas connecté.
        if (session.getAttribute(ATT_SESSION_USER) == null) {
            // Redirection vers la page publique
            //response.sendRedirect(request.getContextPath() + ACCES_PUBLIC);
            //On va changer la ligne dessus sendRedirect par un forwarding pour que le filtre ne la bloque pas en URL /*
            //ceci va donc m'envoyer sur a page /connexion sans que cela affiche la /connexion
            request.getRequestDispatcher(ACCES_CONNEXION).forward(request, response);
        } else {
            // Affichage de la page restreinte, une fois que l'utilisateur existe on pourra accéder aux pages restreintes
            // demandées, c'est le principe de chain.doFilter(request, response)
            chain.doFilter(request, response);
        }
    }

    //------------------------------------ method de l'interface Filter 3 ----------------------------------------------
    public void destroy() {

    }
}
