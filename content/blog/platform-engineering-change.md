+++
title = "Platform Engineering Change"
date = 2025-05-15T08:41:10+10:00
description = "Platform Engineering is people! It's people!"
[taxonomies]
categories = [ "Meta" ]
tags = [ "teams", "meta" ]
+++

Here's pretty much what I do these days for change.
Take what works for you and your situation.

Hope it helps.

## Make Friends

Short list influencers in your organization and build the rapport with them.
These are the people we're going to woo first and move to form a collaborative relationship with.

Consider:

- Tenure - you want someone who's been around a while and will _be_ around a while
- Organisational knowledge
- The "height" at which they can think about things
- Technical capital is key, but political and social don't hurt either

You might want to start with just one.
That'll let you adjust your approach without burning the initiative all at once or overloading yourself.

## Lend an Ear

Get some time with your short list to gather information about pain points and problems they experience.

You're aiming to:

- Collate an _empathetic_ understanding - ideally backed by paper
- Let them feel heard - that means actually listening
- Signal the shift - do something unusual
- Find actionables - ideally common across teams

You can frame it as a vent session to set the tone if you're expecting mostly negative feedback.
Try not to argue or offer any suggestions or solutions.
If they missed some feature or something in the documentation, explore that after.
You don't want it to be adversarial, turn into solutionizing, or get lost in the details.

## Get to Work

<!-- pyml disable-next-line md036 -->
*Solve for one of those problems*

Can't stress this enough.

<!-- pyml disable-next-line md036 -->
**SOLVE A REAL PROBLEM**

If you look at the stuff you currently have, and it *doesn't solve any of these problems*, then ease off on pushing the change.
If it really ticks the boxes - awesome, but you'll probably need at least a little rework.
We can address _how_ work gets into our design pipeline and _what focus_ the work has later on - that's more within the team and thus our control.

## Lean on Me

Use your influencer(s) for first-line review.
Once you've got a solution, go back to at least one of them to see what they think.

- They'll be chuffed you're putting work _into their problem_
- You're _showing_ that you've been listening
- You get a fast-feedback reality check

Avoid making it overly engineered while it's still just a twinkle in your eye.
Whether you go with just a napkin scribble, a design document, or a demo depends.

- What your audience is going to engage with
- The level of investment you can afford/is appropriate.

Something that's going to be quite complex to wire up a demo for can be much more efficient to just diagram up.
Something that really sings when you see it in action and takes little time to build, make a demo!
Something with a lot of uncertainty, napkin it and explore the problem space together.

You can always come back again!
You'll almost certainly not have thought of something.

## One Bite at a Time

Decouple the adoption across teams if you can.
Trying to shift everyone onto a new system puts a lot of support load on you all at once.
No solution survives first contact with reality unchanged, this means the ground will be moving for all teams,
potentially from different sources as team members make non-complimentary changes to the solution.
This decoupling may mean having some deployments or other processes to run in parallel for a while.

## Lure Your Prey

Entice a pilot team.
This is our version of beta testing.
We'll usually find a team with the target pain point, and demo the solution either to the team lead first or straight to the team with the lead's blessing.
It helps if the team lead was the influencer you asked for feedback on the design from.

## Frame Like Mike

Reframe any presentations going forward to be in terms the developers care about.

Some examples of this are:

- Which problem does this address and how?
- Demonstrate common use cases - things they would be expected to do with it daily
- Have a user guide ready to go, link it in the presentation
- Offer more than just a demo session, a workshop where people can clone a repo and follow along is good
- Make a demo repo. Some options:
  - Reference implementation using a toy program that illustrates the new feature, and *only* the new feature.
  - Several branches, showing the progression and use of features building on each one until it's fully realized.

## Wright the Wrong

Set up a time for the change over, make sure you have capacity to support the team as they onboard.
Be ready to make quick changes to both their application's setup and the solution.
Expect to have to rework the solution, that's the point of the pilot!
Anything that generates a question or confusion, add it to the documentation for the solution.
Encourage them to share any notes they've made on it - either to you for feeding into docs or directly as documentation contributions.

<!-- pyml disable-next-line md026 -->
## Wait.

Give it a few weeks of operation, see how it goes.
Swing by and ask the team for feedback.
Adjust until it's running pretty smoothly.
Mind the line between adjusting and adding features, we just want it fit for purpose now.

## Sell, Sell, Sell

Do a wider-audience demo across the teams.
In addition to the now enhanced docs and the reference implementation or workshop,
they can also look at a real-world working example in the pilot AND the engineers can answer questions too - sharing support load.

## Bed, Bask, and Beyond

Bed in the change.
Advertise your win.
Pat your team on the back.
Tidy up those messy bits from the pilot.
...and get ready for the next one!

## Notes

- While presented linearly, this is an ongoing process.
- In a perfect world you measure before and after solution implementation.
- The theory goes the solution should be enticing, but that may not be enough to get priority.
  The usual spiel about management sponsorship and buy-in applies.
- Be careful who you pick for first-line reviews, as some devs may try to make you solve the world's problems upfront.
- If staff disengaged at work that's a handicap, but doesn't mean it's not worth trying
- You may be fundamentally reshaping a culture and relationship, this will take time and particularly, human face time.
- You may have a service mindset, but they might not see it or be willing to place faith in it.
- Failed attempts at things can kindof "scorch" the topic, leaving people predisposed against it.
  That's why the small start and quick adjustment are important, you may not get a second try!
  Ask me about my bot blunder!
- Framing and audience matters.
  There can be a tendency in infra to go "hey look at this cool thing I did".
  There are more compelling ways to show off a solution to people with their own set of problems and goals.
