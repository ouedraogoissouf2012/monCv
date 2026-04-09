package com.cvmobile.service.cv;

import com.cvmobile.dto.CvRequest;
import com.cvmobile.dto.CvResponse;

import java.util.List;

/**
 * Contrat pour le service CRUD des CVs.
 * Ne contient que les operations metier sur les CVs.
 */
public interface ICvService {

    List<CvResponse> getAllCvsByUserId(Long userId);

    CvResponse getCvById(Long cvId, Long userId);

    CvResponse getCvWithDetails(Long cvId);

    CvResponse getCvByPublicToken(String token);

    CvResponse createCv(CvRequest request, Long userId);

    CvResponse updateCv(Long cvId, CvRequest request, Long userId);

    CvResponse duplicateCv(Long cvId, Long userId);

    CvResponse generateShareToken(Long cvId, Long userId);

    void deleteCv(Long cvId, Long userId);

    CvResponse createVariant(Long parentCvId, String jobDescription, String label, Long userId);

    List<CvResponse> getVariantsByParentId(Long parentCvId, Long userId);
}
