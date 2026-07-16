package com.cvmobile.service.ai;

import com.cvmobile.dto.ApplicationMessagesResponse;

public interface IApplicationMessageService {
    ApplicationMessagesResponse generate(Long cvId, Long userId, String jobDescription, String tone);
}
