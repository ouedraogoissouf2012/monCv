package com.cvmobile.config;

import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

import java.util.concurrent.ThreadPoolExecutor;

/**
 * Infrastructure d'execution asynchrone (issue #495).
 *
 * <p>Motivation securite : l'envoi SMTP du lien de reinitialisation de mot de passe
 * est bloquant (jusqu'a plusieurs secondes au timeout). Effectue de facon synchrone,
 * il n'a lieu que si l'email existe, creant un ecart de latence observable qui permet
 * l'enumeration des comptes par timing. Cet executor sort l'envoi du chemin de reponse
 * afin que {@code requestReset} revienne en temps constant, email connu ou non.
 *
 * <p>Le pool est <strong>borne</strong> (jamais {@code SimpleAsyncTaskExecutor}, qui
 * cree un thread par tache) et sa politique de rejet est <strong>explicite</strong> :
 * en cas de saturation la tache est rejetee (jamais executee dans le thread appelant),
 * pour ne pas reintroduire la faille de timing sous charge. Un email de reset perdu en
 * saturation extreme est acceptable (l'utilisateur peut relancer la demande) ; rendre le
 * temps de reponse a nouveau dependant de l'existence du compte ne l'est pas.
 */
@Slf4j
@Configuration
@EnableAsync
public class AsyncConfig {

    /** Nom du bean executor dedie a l'envoi d'emails ; reference par {@code @Async}. */
    public static final String EMAIL_EXECUTOR = "emailTaskExecutor";

    private static final int CORE_POOL_SIZE = 2;
    private static final int MAX_POOL_SIZE = 5;
    private static final int QUEUE_CAPACITY = 100;
    private static final int AWAIT_TERMINATION_SECONDS = 30;
    private static final String THREAD_NAME_PREFIX = "email-async-";

    @Bean(name = EMAIL_EXECUTOR)
    public ThreadPoolTaskExecutor emailTaskExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(CORE_POOL_SIZE);
        executor.setMaxPoolSize(MAX_POOL_SIZE);
        executor.setQueueCapacity(QUEUE_CAPACITY);
        executor.setThreadNamePrefix(THREAD_NAME_PREFIX);
        // Rejet explicite (aucun repli sur le thread appelant) : preserve le temps de
        // reponse constant meme a saturation. Le rejet est trace par le sender.
        executor.setRejectedExecutionHandler(new ThreadPoolExecutor.AbortPolicy());
        // Vidange propre a l'arret : laisse les envois en cours se terminer.
        executor.setWaitForTasksToCompleteOnShutdown(true);
        executor.setAwaitTerminationSeconds(AWAIT_TERMINATION_SECONDS);
        executor.initialize();
        return executor;
    }
}
