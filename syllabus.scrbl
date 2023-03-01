#lang scribble/manual
@(require (for-label racket/contract))

@(define (mailto addr)
   (hyperlink (format "mailto:~a" addr) addr))

@title{Syllabus}

@section{Course description}

See the homepage.

@section{Course information}

@tabular[
#:style 'boxed
#:column-properties '(left left)
(list
  (list @bold{Course number} "CSCI-B 629")
  (list @bold{Course title} "Topics in Programming Languages: Proofs as Programs")
  (list @bold{Location} "Ballantine Hall 313")
  (list @bold{Time} "Tuesday and Thursday, 3:00-4:15 PM"))
]

@section{Contacts}

@tabular[
#:style 'boxed
#:column-properties '(center)
@;#:row-properties '(bottom-border)
(list
  (list @bold{Instructor} @bold{Contact Details} @bold{Office} @bold{Office Hours})
  (list "Tulip Amalie" @mailto["hrlevi@iu.edu"] "Luddy Hall 3015M" "10-11:30AM Tuesday")
  (list "" "" "" "12:30-2:30PM Friday")) 
]

@section{Prerequisites}

This course has no prerequisites on the registrar.

Familiarity with everything in CSCI-C 311, CSCI-H 311, or CSCI-B 521 (all the same course) is
necessary for this course. If you have not taken 311, you will not be able to succeed in this
course. If you have @italic{only} taken 311 and have no other functional programming background,
this course will be very difficult, but should be doable.

To gauge whether or not whether you have the minimum knowledge to do this course, ask yourself
the following questions, all of which should be in the affirmative:
@itemlist[
@item{Have you used pattern matching to destructure data?}
@item{Using @tt{foldr}, can you write @tt{map}? What about @tt{filter}?}
@item{Have you ever written an interpreter?}
@item{Do you know what a syntax tree is, and understand the duality between code and data?}
@item{Do you know what the purpose of a continuation is? Can you write an interpreter for a language
with @tt{call/cc} or @tt{let/cc}?}
@item{Given a term in the untyped lambda calculus, can you give me a type for it?}
]

In addition, this course will be taught primarily in Racket and Agda. We will be using a decent
amount of Racket features, but given knowledge of general functional programming, it should not
be difficult to pick up. Doing CSCI-P 423 (Compilers) in Racket is great background.

Having a more complex course in functional programming, such as CSCI-P 424 (Advanced FP) or
CSCI-B 522 (Programming Language Foundations) will be deeply beneficial, but not strictly required.

Having some background in logic (such as a math logic course) is also deeply beneficial, but not
strictly required. Having some background in purely symbolic logic (such as CSCI-C 241 or CSCI-H 241)
with no background on @italic{why} these systems work might be useful, but in this class we care much
more about results @italic{about} our logic than results @italic{in} our logic, at least for the first
half.

@section{Course materials}

No textbook is required. There will be weekly lecture notes posted as they are written,
and assignments posted as they are assigned.

Some useful, but not strictly necessary, resources are:
@itemlist[
@item{@italic{Types and Programming Languages}, by Benjamin C. Pierce}
@item{@italic{@hyperlink["https://davidchristiansen.dk/tutorials/nbe/"]{Checking Dependent Types with Normalization by Evaluation}}, by David Christiansen}
@item{@italic{@hyperlink["https://cs.uwaterloo.ca/~plragde/flaneries/LACI/"]{Logic and Computation Intertwined}}, by Prabhakar Ragde}
@item{@italic{@hyperlink["https://arxiv.org/pdf/1908.05839.pdf"]{Bidirectional Typing}}, by Jana Dunfield and Neel Krishnaswami}
@item{@italic{@hyperlink["https://www.youtube.com/watch?v=R5NMX8FBlWU"]{An Algebraic Approach to Typechecking and Elaboration}}, by Bob Atkey
(@hyperlink["https://bentnib.org/docs/algebraic-typechecking-20150218.pdf"]{slides})}
]
This list will be updated throughout the semester.

@section{Assignments and grading}

This is a 600-level topics course. If you are in this class, you are here because you want to be,
ideally out of genuine interest in the subject matter and not to fulfill an arbitrary requirement.
If you are not here because you want to be, or you think this class will be deeply monotonous,
consider taking a different course.

Grading, however, will reflect this. This class will have both worksheets and programming assignments,
assigned on Monday every two weeks (starting from Week 2).

Worksheets are @bold{not graded}, and solutions will be posted one week after they are given. These are to
be more traditional exercises, in which you sketch out proofs or derivations on paper. You are expected to
complete these, because the knowledge from them will make the programming assignments significantly easier.

Programming assignments are partially auto-graded, and should be submitted to GitHub Classroom.
These assignments make up @bold{100% of your grade for this course}.

Agda assignments should not use postulates or @tt{trustMe} anywhere, aside from postulates provided by
the instructor. Simply postulating everything will pass the autograder, but net you a 0%.

Sharing code is not only acceptable, but encouraged. However, two people should not submit the exact same
assignment. When collaborating with another student, you should leave a comment on the function or tactic
that you collaborated on saying who else worked on it.

There are no exams (!!!).

@section{IMPORTANT: Systematic program design}

@bold{This section is primarily relevant for the Racket part of the course.}

While there is an autograder that verifies functionality, we will also be grading you based on program design.
There are many, many different ways to write a correct program, but in this course, we ascribe to a specific
way of writing type-checkers.

While the goal of an assignment may be "write a type-checker for this module language", when you submit an
assignment, you should follow the design recipe for all functions and tactics, and you should finish each
individual exercise. The goal is not to simply produce a working program.

All of your functions should have a signature (or contract) or purpose statement. If using
@racket[define/contract] or some other similar form, no signature is required.

All of your functions should have extensive RackUnit tests. We will go over how to use RackUnit in class.
If you have taken C211, the amount of tests expected is about the amount of tests you would write in that
course. You should write your tests before you write your code.

Almost all of your functions should follow the structural decomposition template. In this class, it will be
very rare that any function decomposes the input in a way that isn't just a straightforward pattern match.
This is, however, no longer strictly a hard and fast rule.

We will grade you on design. If your solution is incomprehensible but passes the autograder, it will not get
points. If your solution does not have any tests but passes the autograder, it will lose points.
