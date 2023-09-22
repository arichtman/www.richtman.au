+++
title = "Prediction Machines"
date = 1970-01-01
description = "Summary of the 2022 revised edition."
[taxonomies]
categories = [ "Personal", "Meta" ]
tags = [ "reference", "book", "professional-development", "summary" ]
+++

# Prediction Machines

## Introduction

AI is a prediction technology, predictions are inputs to decision-making, and economics provides a perfect framework for understanding the trade-offs underlying any decision.

When the price of something falls, we use more of it. [Ed. Jevon's Paradox]

Reframing a technological advance as a shift from expensive to cheap or from scarce to abundant is invaluable for thinking...

When an input such as prediction becomes cheap, this can enhance the value of other things. Economists call these "complements".

[In order to strategise]
First, you must invest in gathering intelligence on how fast and how far the dial on the prediction machines will turn for your sector and applications.
Second, you must invest in developing a thesis about the strategic options created from turning the dial.

Prediction facilitatec decisions by reducing uncertainty, while judgement assigns value.

Judgement is the skill used to determine a payoff, utility, reward, or profit.

The most significant implication of prediction machines is that they increase the value of judgement.

## Prediction

Prediction is the process of filling in missing information.
Prediction takes information you have, often called data, and uses it to generate information you don't have.

The change frm 98% to 99.9% has been transformational.
An improvement frm 98% to 99.9% means mistakes fall by a factor of twenty.

A decision maker is _risk averse_ if they chose not to take a fair bet.

If risk exposure is not the constraint, then insurance won't do anything.

When forecasts are imperfect, it becomes important what is going on under the hood.

_Option Value_ is the value of not committing until as late as possible.

Risk can be managed in two broad ways.
- _Insurance_: take actions that reduce the costs associated with bad outcomes.
- _Protection_: take actions that reduce the probability of a bad outcome.

When you use insurance tto minimize wast, the waste is visible.
By contrast, with protection, the waste may be harder to see.

[_Regression_] Finds a prediction based on the average of what has occurred in the past.

_The Conditional Average_

_Goodness of Fit_

_Customer Churn_

Regression minimizes prediction mistakes on average, and punishes large errors more than small ones.

Even if it averabes out to the correct answer, regression can mean never actually hitting the target.
Unlike regression, machine learning predictions might be wrong on average, but when the predictions miss, they often don't miss by much.

_Deep Learning_

_Back Propagation_

Traditional statistical methods require the articulation of hypotheses or at least of human intuition for a model specification.
Machine learning has less need to specify in advance what goes into the model and can accommodate the equivalent of much more complex models with many more interactiosn between variables.

_The New Oil_ == Data

Three types of data for AI:
- _Input data_: fed to the algorithm and used to produce a prediction.
- _Training data_: used to generate the algorithm in the first place.
- _Feedback data_: used to improve the algorIthm's performance with experience.
In some situations, considerable overlap exists, such that the same data plays all 3 roles.

_Independent Variables_

_Dependent Variables_

The number of individuals [units of analysis, data] required depends on two factors:
first, how reliable the signal is relative to the noise
second, how accurate the prediction must be to be useful

_Power Calculations_: tools for assessing the amount of data required given the expected reliability of the prediction and the need for accuracy.

Accurate prdictions require more units to study, and acquiring these additional units can be costly.

Data may have increasing or decreasing returns to scale.
Decreasing returns to scale means as you get more data, each additional piece is less valuable.
This might not be true when considering the outcomes and costs.

Understand the relationship between adding more data, enmancing prediction accuracy, and increasing value creation.

The larger the number of events, the likelier the outcome will be close to the average.

The interaction effect means as the number of dimensions for interactions grows, humans' ability to form accurate prections diminishes.

_Known Knowns_: rich data, good predictions
_Known Unknowns_: too little data, difficult to predict
_Unknown Unknowns_: events not captured by past experience or what is present in the data but nonetheless possible. Black Swan.
_Unknown Knowns_: wrong but confident predictions?

_Reverse Causality_

_Omitted Variables_: factors that influence but aren't in the input data or model

_Counterfactual_: what would have happened if you had taken a different action

Once unmodeled situations have been identified, they are no longer unknown knowns.
Either they find solutions to generate good predictions, so the problems become known knowns.
Or they cannot find solutions, so they become known unknowns

The blending of AI for prediction and humans for judgement is classic division of labour.
Either the prediction is provided to the human to combine with their own assessment.
Or the prediction can be used for assessment or a second opinion after the fact.

Prediction machines can scale in a way humans can't.
But they struggle to predict in unusual cases for which there's not much data.

_Prediction by Exception_: the prediction machine runs as normal, but when it hits an exceptional case, a human is called to intervene.

## Decision-Making

When a _decision_ is made, _input data_ from the world is used to make a _prediction_.
The _prediction_ is possible because _training_ occurred about relationships between different types of data, and which data is most closely associated with a situation.
Combining the prediction with _judgment_ on what matters, the decision maker can choose an _action_.
The _action_ leads to an _outcome_, which has an associated _reward_ or payoff.
The outcome is a consequence of the decision.
Outcomes may also provide _feedback_ to help improve the next _prediction.

Judgment, data, and action, for now, remain firmly in the realm of humans.
They are cmplements to prediction, meaning they incraese in value as prediction becomes cheap.

_Reward Function_

Prediction machines are valuable because:
- often faster, better, cheaper than humans
- prediction is key in decision-making under uncertainty
- decition-makins is ubiquitous

Prediction machines don't provide judgment, only humans do.

Better faster, and cheaper predictions will give us more decisions to make.

The cost of figuring out payoffs will mostly be in time.
Humans experience the cognitive costs of judgment as a slower decision-making process.
Humans have their own knowledge of why they are doing something, which gives them weights that are both idiosyncratic and subjective.
Uncertainty increases the cost of judging the payoffs for a given decision.
It's important to determine the payoffs for acting on wrong decisions, as much as right ones.

_Reward Function Engineering_: the job of determining tHe rewards to various actions, given the predictions that the AI makes.

For the forseeable future, humans will have a role in prediction and judgment when unusual situations arise.

To observe the counterfactual, two solutions:
- _Experiments_
- _Modeling_
Experiments are more powerful but modeling is cheaper and more feasible.

_Satisficing_

_Automation_: when a machine undertakes an entire task, not just prediction.

When speed is needed, the benefit of ceding control to the machine is high.
However, if the prrediction leads too directly to an obvious course of action, then the case for leaving human judgment in the loop is diminished.

_Externalities_: costs that are incurred by others than the decision maker.

Tasks most likely to be automated first:
- Other elements already automated bar prediction
- Gains from speed improvements to prediction are appealing
- Gains from improved signal-response delay are appealing

_Stakes_: expected losses that arise when there is an error in prediction

When the stakes are high, utilizing AI prediction involves complementary investments in measures that manage the additional risks created.
That management will involve either some form of insurance or protection.

_True Positive_

_False Positive_

When AI predictions are faster and cheaper, but not better, than human ones, adopters need to be careful.
When the consequences of a mistake are low, faster and cheaper may be enough.

_Loss Functions_: measures of how accurate a prediction is relative to the stakes and the consequences of following the prediction with action.

While judgment tells you what the value of different possibilities is overall, stakes focus on one particular aspect of that judgment - i.e. the relative consequences of errors.

The choice about whether to fully automate a decision or not on the basis of AI prediction relies on how measurable stakes can be.

## Tools

AI use requires rethinking processes.

The unit of AI tool design is not:
- the job
- the occupation
- the strategy
It's the task.
Tasks are collections of decisions.
Decisions are based on prediction and judgment and informed by data.

Tools can change workflows in two ways:
- Removing tasks
- Adding tasks

Deriving a real benefit from implementing an AI tool requires rethinking or re-engineering the entire workflow.

Tool design can be aided by using _The AI Canvas_.
Which looks at several lenses.

- Action: What are you trying to do?
- Prediction: What do you need to know to make the decision?
- Judgment: How do you value different outcomes and errors?
- Outcome: What are your metrics for task success?
- Input: What data do you need to run the predictive algorithm?
- Training: What data do you need to train the algorithm?
- Feedback: How can you use the outcomes to improve the algorithm?

Fully automated tasks can fail if even one piece fails.

Automation that elimenatess a human from a task does not necessarily eliminate them from a job.

Implementation of AI tools has 4 implications for jobs:
- Augmentation - like spreadsheets
- Contract - like fulfillment
- Reconstitution - some shifting/redistribution of tasks
- Shift - skills focus of a role may change

## Strategy

Three drivers of AI at the strategic level:
- Strategic trade-off or dilemma
- Can be addressed by reducing uncertainty
- Feasible prediction machine that reduces uncertainty _enough_

Eventually the demand will grow and supply costs will drop enough.
Where this balance is depends on the business.

External senior advisors are common for AI implementations.

To make the most of predictoin machines, you need to rethink the reward functions throughout your organization to better align with your true goals.

Training data is used at the beginning to train an algorithm, but once the prediction machine is running, it is not useful anymore.

C-suite leadership must not fully delegate AI strategy to ICT.
Powerful AI tools must cross organizational boundaries to reengineer processes.
AI tools in one portion of the business may have effects on other parts.
Further, the productivity enhancements themselves may become a key factor/driver of the strategy itself.

The increasing value of judgment may lead to changes in organizational hierarchy.
There may be higher returns in putting different roles or people in positions of power.

Uncertainty has a major impact on a business's boundaries.
Better prediction drives more outsourcing, while complexity tends to reduce it.

AI will shift HR management toward the relational and away from the transactional.

The importance of judgment means that employee contracts need to be more subjective.

Better prediction increases the uncertainty you have over the quality of human workh performed.
Thus, you need to keep your reward function engineers and other judgment-focussed workers in-house.

For AI startups, owning the data that allows them to learn is particularly crucial.
Otherwise they will be unable to improve their product over time.

Companies buy data because they can't collect it themselves.
[Ed. Not really, as always it's a trade-off]
Not surprisingLy, they buy data that hElps them identiffy high-value customers.
They also may buy data that helps them avoid advertising to low-value customers.

Without direct access to the data, the advertiser buys the prediction.
[Ed. Here we go with the rent-seeking capitalists again]

Data and prediction machines are complements, procuring or developing an AI will be of limited value unless you have the data to feed it.
If the data resides with others, you need a strategy to get it.
If the data resides with an exclusive or monopoly provider, then you may find yourself at risk of having that provider appropriate the entire value of your AI.
If the data resides with competitors, there may be no strategy that would make it worthwhile to procure it from them.
If the data resides with consumers, it can be exchanged in return for a better product or higher-quality service.

If the prediction machine is an input that you can take off the shelf, then you can treat it as a commodity and purchase, provided AI isn't a core strategic pillar.
If AI is core to strategy, then both machine and data must be insourced.

Judgment quality is hard to specify in-contract and difficult to monitor.

AI-first means devoting resources to data collection and learning at the expense of important short-term considerations like;
immediate customer experience,
revenue,
user numbers.

Learning takes time, and often results in inferior performance (especially for consumers).

_Disruptive technologies_: ones some established companies will find difficult to adopt quickly.

_Inventor's dilemma_: where established firms don't want to disrupt existing customers, even if long-term it would be optimal.

When they first appear, innovations might not be bgood enough to serve the customers of established companies in an industry, but they may be good *enough* to provide a new startup with enough customers in some niche area to build a product.

Where the long-term potential impact is likely to be enormous, the whiff of disruptino may drive early adoption, even by incumbents.

_Learning-by-using_: where firms improve their product design through interactions with users.

_Supervised learning_: when you already have good data.

_Reinforcement learning_: No good data but you can evaluate performance after the fact.

_Dog fooding_

_Beta testing_

We have different definitions for _good enough_ when it comes to how much training humans require in different jobs.
Same for machines.

It can be a major strategic decision when to shift from in-house training to on-the-job.
Putting products in the wild earlier accelerates learning but risks harming the brand and customers.
Putting later slows learning but allows more time to improve the product in-house, and protect brand and customers.
Simulation-based learning protects brand and customer, but has risks as no simulation is sufficiently complete.
AI can be retrained in short feedback loops based on real data, but at the cost of quality assurance.
Companies must trade-off how quickly they should use an AI in the real world.

_Adversarial machine learning_

p216
