package com.cvmobile.repository;

import com.cvmobile.model.UploadedPhoto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface UploadedPhotoRepository extends JpaRepository<UploadedPhoto, String> {
    boolean existsByFilenameAndOwnerId(String filename, Long ownerId);

    @Query("SELECT photo.filename FROM UploadedPhoto photo WHERE photo.owner.id = :ownerId")
    List<String> findFilenamesByOwnerId(@Param("ownerId") Long ownerId);
}
