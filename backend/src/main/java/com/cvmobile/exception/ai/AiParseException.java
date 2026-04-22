package com.cvmobile.exception.ai;

/**
 * Levee quand la reponse du provider IA est malformee (JSON invalide,
 * structure inattendue, champs manquants dans la reponse OpenAI-like).
 * Retryable car l'IA peut retourner une reponse valide au prochain appel.
 * Cote HTTP : 502 Bad Gateway + code "AI_PARSE_ERROR".
 */
public class AiParseException extends AiServiceException {

    public AiParseException(String provider, String detail, Throwable cause) {
        super(provider, "AI_PARSE_ERROR",
                "Reponse invalide de " + provider + " : " + detail,
                cause, null);
    }
}
