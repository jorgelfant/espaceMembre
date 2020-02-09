package com.exemple.servlets;

import com.exemple.beans.Utilisateur;
import com.exemple.forms.ConnexionForm;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

public class Connexion extends HttpServlet {
    public static final String ATT_USER = "utilisateur";
    public static final String ATT_FORM = "form";
    public static final String ATT_SESSION_USER = "sessionUtilisateur";
    public static final String VUE = "/WEB-INF/connexion.jsp";

    public void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        // Affichage de la page de connexion
        this.getServletContext().getRequestDispatcher(VUE).forward(request, response);
    }

    public void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        //request.setCharacterEncoding("UTF-8")  faire ca est laborieux et il faudrait faire cela dans tt les servlets
        // Préparation de l'objet formulaire
        ConnexionForm form = new ConnexionForm();

        // Traitement de la requête et récupération du bean en résultant
        Utilisateur utilisateur = form.connecterUtilisateur(request);

        // Récupération de la session depuis la requête
        HttpSession session = request.getSession();

        // Si aucune erreur de validation n'a eu lieu, alors ajout du bean Utilisateur à la session, sinon suppression
        // du bean de la session.

        if (form.getErreurs().isEmpty()) {
            //if (session.isNew()) {
            session.setAttribute(ATT_SESSION_USER, utilisateur);
            //}
        } else {
            session.setAttribute(ATT_SESSION_USER, null);
        }

        // Stockage du formulaire et du bean dans l'objet request
        request.setAttribute(ATT_FORM, form);
        request.setAttribute(ATT_USER, utilisateur);

        this.getServletContext().getRequestDispatcher(VUE).forward(request, response);
    }
}
