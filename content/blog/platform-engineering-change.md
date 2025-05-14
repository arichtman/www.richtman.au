+++
title = "Platform Engineering Change"
date = 2025-05-15T08:41:10+10:00
description = "Platform Engineering is people! It's people!"
draft = true
[taxonomies]
categories = [ "Meta" ]
tags = [ "teams", "meta" ]
+++

Thoughts:
- Multiple facets to this; influence, change management
- If they're disengaged at work that's a handicap, but doesn't mean it's not worth trying
- You're fundamentally reshaping a culture and relationship, this will take time and particularly, human face time.
- I know you have a service mindset, but they might not see is or be willing to place faith in it.
- Failed attempts at things can kindof "scorch" the topic, leaving people predisposed against it. This can manifest as "yea okay sure" indifference.
- Framing and audience matters. There can be a tendency in infra to go "hey look at this cool thing I did".
  There are more compelling ways to show off a solution to people with their own set of problems.

Concrete ideas (i.e. this is basically how we operate):
- Short list your influencers and build the rapport with them.
  Considure tenure, organisational knowledge, the "height" at which they can think about things, and technical, social, and political capital.
  These are the people we're going to woo first and move to form a collaborative relationship with.
  You might want to start with just one for now.
  That'll let you adjust your approach without burning this idea with all your influencers at once.
- See if you can get some time with your short list to gather information about pain points and problems they experience.
  The aims are: collate an _empathetic_ understanding - ideally backed by paper, to make them feel heard, to signal a shift, and to find a cross-team view of actionables.
  You can frame it as a vent session to set the tone if you're expecting mostly negative feedback.
  I would not argue or offer any suggestions or solutions - this is more a therapy session.
  If they missed some feature or something in the documentation, explore that after - you don't want it to turn adversarial or into the weeds of the solution.
- *Solve for one of those problems*.
  Can't stress this enough.
  If you look at the stuff you currently have, and it *doesn't solve any of these problems*, then probably ease off on pushing the change.
  If it really ticks the boxes - awesome, but you'll probably need at least a little rework.
  We can address _how_ work gets into our design pipeline and _what focus_ the work has later on - that's more within the team and thus our control.
- Use your influencers for first-line review.
  Once you've got a solution, go back to at least one of them to see what they think.
  A) they'll be chuffed you're putting work _into their problem_
  B) You're *showing* that you're listening
  C) You get a fast-feedback reality check. Be careful who you pick though as some devs may try to make you solve the world's problems upfront.
  You'll get nowhere making it overly engineered while it's still just a twinkle in your eye.
  Whether you go with just a napkin scribble, a design document, or a demo depends on A) what your audience is going to engage with, and B) the level of investment you can afford/is appropriate.
  Something that's going to be quite complex to wire up a demo for can be much more efficient to just diagram up.
  Something that really sings when you see it in action and takes little time to adjust, make a demo!
  Something with a lot of uncertainty, napkin it and explore the problem space together.
  You can always come back again! You'll almost certainly not have thought of something.
- Decouple the adoption across teams if you can.
  Trying to shift everyone onto a new system puts a lot of support load on you all at once.
  No solution survives first contact with reality unchanged, this means the ground will be moving for all teams, potentially from different sources as team members make non-complimentary changes to the solution.
  This may mean working some deployments to run in parallel for a while.
- Entice a pilot team. This is our version of beta testing.
  We'll usually find a team with the target pain point, and demo the solution either to the team lead first or straight to the team with the lead's blessing.
  Obviously it helps tremendously if the lead was the influencer you asked for feedback on the design from.
- Reframe any presentations going forward to be in terms the developers care about.
  Which, of the *concrete things they have told you about*, does this address and how?
  Consider demonstrating common use cases - things they would be expected to do with it daily.
  Have a user guide ready to go, link it in the presentation.
  Consider offering more than just a demo session, a workshop where people can clone a repo and follow along is good.
  Consider offering a demo repo, lots of options to do this, we've done one style that's a reference implementation so a toy program that illustrates the new feature clearly,
  and another that was several branches, showing the progression and use of features on each one until it was fully realized.
- Pilot: make sure you have capacity to support the team as they onboard.
  Be ready to make quick changes to both their application's setup and the solution.
  Expect to have to rework the solution, that's the point of the pilot!
  Anything, and I mean anything that generates a question or confusion, add it to the documentation for the solution.
  Encourage them to share any notes they've made on it - either to you for feeding into docs or directly as contributions.
  Our docs repo is not sacred ground, they're welcome to contribute.
- Wait.
  Give it a few weeks of operation, see how it goes.
  Swing by and ask the team for feedback.
  Adjust until it;s running pretty smoothly.
- Sell!
  Now go out and do a wider demo across the teams.
  In addition to the now enhanced docs and the reference implementation or workshop,
  they can also look at a real-world working example in the pilot AND the engineers can answer questions too - sharing support load.

The theory goes the solution should be enticing, but that may not be enough to get priority.
In a perfect world you measure before and after solution implementation.
You might get mangement buy-in for the pilot and use the numbers to get top-down push for adoption post-pilot.
