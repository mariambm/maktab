package com.maktab.payment.persistence;

import com.maktab.payment.domain.PaymentPeriod;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PaymentPeriodRepository extends JpaRepository<PaymentPeriod, UUID> {

    List<PaymentPeriod> findByOrganisationIdOrderByMonthDesc(UUID organisationId);

    Optional<PaymentPeriod> findByIdAndOrganisationId(UUID id, UUID organisationId);

    boolean existsByOrganisationIdAndMonth(UUID organisationId, LocalDate month);
}
