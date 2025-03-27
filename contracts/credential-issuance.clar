;; Credential Issuance Contract
;; Allows authorized institutions to issue professional certifications

(define-data-var contract-owner principal tx-sender)

;; Map of authorized issuers
(define-map authorized-issuers principal bool)

;; Credential structure
(define-map credentials
  { credential-id: (string-ascii 64), recipient: principal }
  {
    issuer: principal,
    credential-type: (string-ascii 64),
    issue-date: uint,
    expiry-date: uint,
    metadata-uri: (string-ascii 256),
    revoked: bool
  }
)

;; Events
(define-public (emit-credential-issued (credential-id (string-ascii 64)) (recipient principal))
  (ok (print { event: "credential-issued", credential-id: credential-id, recipient: recipient }))
)

;; Authorization functions
(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u100))
    (ok (var-set contract-owner new-owner))
  )
)

(define-public (add-authorized-issuer (issuer principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u101))
    (ok (map-set authorized-issuers issuer true))
  )
)

(define-public (remove-authorized-issuer (issuer principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u101))
    (ok (map-delete authorized-issuers issuer))
  )
)

(define-read-only (is-authorized-issuer (issuer principal))
  (default-to false (map-get? authorized-issuers issuer))
)

;; Credential issuance functions
(define-public (issue-credential
    (credential-id (string-ascii 64))
    (recipient principal)
    (credential-type (string-ascii 64))
    (expiry-date uint)
    (metadata-uri (string-ascii 256)))
  (let
    ((issuer tx-sender)
     (issue-date (get-block-info? time (- block-height u1))))

    ;; Check if issuer is authorized
    (asserts! (is-authorized-issuer issuer) (err u102))

    ;; Check if credential already exists
    (asserts! (is-none (map-get? credentials { credential-id: credential-id, recipient: recipient })) (err u103))

    ;; Issue the credential
    (map-set credentials
      { credential-id: credential-id, recipient: recipient }
      {
        issuer: issuer,
        credential-type: credential-type,
        issue-date: (default-to u0 issue-date),
        expiry-date: expiry-date,
        metadata-uri: metadata-uri,
        revoked: false
      }
    )

    ;; Emit event
    (emit-credential-issued credential-id recipient)
  )
)

;; Read credential information
(define-read-only (get-credential (credential-id (string-ascii 64)) (recipient principal))
  (map-get? credentials { credential-id: credential-id, recipient: recipient })
)
