#lang scribble/manual

@(require gregor "common.rkt")
@title{Course calendar}

@; by: Lylat, 2023-01-23
We list the primary topics of each lecture on this calendar, for reference.
If a topic isn't finished in one lecture, it will be moved down the calendar.

If a topic is finished and there is remaining time, we will have time to work on homework,
but will not speed up the class unless there is overwhelming consensus to do so.

@tabular[
  #:style 'boxed
  #:column-properties '(left right)
  #:row-properties '(bottom-border ())
  `(,(list @bold{Date} @bold{Topic})
    ,@(for/list ([als (sort topic-dict moment<? #:key car)])
      ; render dates
      (list (~t (car als) "E, MMM d") (cdr als))))
]
