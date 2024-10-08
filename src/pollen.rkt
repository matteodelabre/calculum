#lang racket
(require
  racket/file
  gregor
  pollen/core pollen/decode pollen/tag pollen/pagetree
  txexpr)

(current-locale "fr")

; URLs

;; Root URL of the live website
(provide site-root)
(define site-root "https://calculum.ca")

;; Build a site-local path to a page
(provide local-url)
(define (local-url page)
  (string-trim (format "/~a" page) "index.html" #:right? #t))

;; Build a fully-qualified URL to a page
(provide full-url)
(define (full-url page)
  (format "~a~a" site-root (local-url page)))

;; Make an internal link
(provide in-link)
(define (in-link page . contents)
  `(a ((href ,(local-url page)))
      ,@contents))

;; Make an external link
(provide out-link)
(define (out-link url . contents)
  `(a ((href ,url)
       (rel "noopener noreferrer")
       (target "_blank"))
      ,@contents))

;; Make a heading which can be linked to
(provide link-h2)
(define (link-h2 target . contents)
  `(h2 ((id ,target))
     (a ((href ,(string-append "#" target)))
       ,@contents)))

(provide link-h3)
(define (link-h3 target . contents)
  `(h3 ((id ,target))
     (a ((href ,(string-append "#" target)))
       ,@contents)))

; Posts

;; Get the list of posts starting from the most recent one
(provide list-posts)
(define (list-posts path)
  (pagetree->list (get-pagetree path)))

;; Retrieve the title of a given post
(provide post-title)
(define (post-title [metas (current-metas)])
  (select-from-metas 'title metas))

;; Retrieve the subtitle of a given post
(provide post-subtitle)
(define (post-subtitle [metas (current-metas)])
  (select-from-metas 'subtitle metas))

;; Retrieve the UUID of a given post
(provide post-uuid)
(define (post-uuid [metas (current-metas)])
  (string-append "urn:uuid:" (select-from-metas 'uuid metas)))

;; Retrieve the date and time of a given post
(provide post-date)
(define (post-date [metas (current-metas)])
  (iso8601->moment (select-from-metas 'date metas)))

;; Retrieve and format the date of a given post in ISO-8601
(provide post-iso-date)
(define (post-iso-date [metas (current-metas)])
  (~t (post-date metas) "yyyy-MM-dd'T'HH:mm:ssXXX"))

;; Retrieve and format the date of a given post for humans
(provide post-human-date)
(define (post-human-date [metas (current-metas)])
  (~t (post-date metas) "d MMM y à H 'h' mm"))

;; Check if a post’s date is in the future
(provide post-upcoming?)
(define (post-upcoming? [metas (current-metas)])
  (moment<? (now/moment) (post-date metas)))

;; Retrieve the summary of a given post
(provide post-summary)
(define (post-summary [metas (current-metas)])
  (select-from-metas 'summary metas))

;; Retrieve the author of a given post
(provide post-author)
(define (post-author [metas (current-metas)])
  (or (select-from-metas 'author metas) "inconnu"))

; Other tags

(provide datetime)
(define datetime (default-tag-function 'time))

;; Math

(provide math)
(define (math . xs)
  `(mathjax ,(apply string-append `("\\(" ,@xs "\\)"))))

(provide display-math)
(define (display-math . xs)
  `(mathjax ,(apply string-append `("\\[" ,@xs "\\]"))))

;; Problems

(provide problem)
(define (problem id name difficulty . contents)
  `(li ((class "problem"))
       (a ((href ,(string-append "https://open.kattis.com/problems/" id)))
          "“" ,name "”")
       " "
       (span ((class "problem-difficulty")
              (style ,(string-append "--color: hsl("
                                     (number->string
                                      (+ (* (/ (- (string->number difficulty) 1) 9) -100) 100))
                                     "deg 95% 35%)")))
             ,difficulty)
       " — "
       ,@contents))

;; LeetCode Problems

(provide leetcode-problem)
(define (leetcode-problem url name difficulty . contents)
  `(li ((class "leetcode-problem"))
       (a ((href ,url))
          "“" ,name "”")
       " "
       (span ((class "leetcode-problem-difficulty")
              (style ,(string-append "--color: hsl("
                                     (number->string
                                      (cond
                                       [(string-ci=? difficulty "Easy") 120]   ;; Convert to number
                                       [(string-ci=? difficulty "Medium") 40]  ;; Convert to number
                                       [(string-ci=? difficulty "Hard") 0]     ;; Convert to number
                                       [else 200]))  ;; Default color if no match, as a number
                                     "deg 95% 35%)")))
             ,difficulty)
       " — "
       ,@contents))

;; Updated problem macro to accept leetcode problems

(provide problem-with-leetcode)
(define (problem-with-leetcode id name difficulty leetcode-problems . contents)
  `(li ((class "problem"))
       (a ((href ,(string-append "https://open.kattis.com/problems/" id)))
          "“" ,name "”")
       " "
       (span ((class "problem-difficulty")
              (style ,(string-append "--color: hsl("
                                     (number->string
                                      (+ (* (/ (- (string->number difficulty) 1) 9) -100) 100))
                                     "deg 95% 35%)")))
             ,difficulty)
       " — "
       ,@contents
       ;; Include the LeetCode problems directly inside the li
       ,@(when leetcode-problems
           `((ul ((class "leetcode-problems"))
                 ,@leetcode-problems)))))

; Decoding

;; Turn double line breaks into new paragraphs but
;; leave single line breaks untouched
(define (decode-paragraphs-only contents)
  (decode-paragraphs contents
    #:linebreak-proc (λ (x) (decode-linebreaks x " "))))

(provide root)
(define (root . contents)
   `(@ ,@(decode-elements contents
          #:txexpr-elements-proc decode-paragraphs-only)))


;; Define the code macro using `define-tag-function`
(provide code)
(define (code language . contents)
  ;; Combine contents into a single string separated by newlines
  (define code-content (string-join contents "\n"))
  ;; Generate HTML markup for the code block
  `(pre ((class ,(string-append "language-" language)))
        (code ,code-content)))