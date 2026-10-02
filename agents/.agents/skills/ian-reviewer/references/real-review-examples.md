# Review examples

These come from Ian's real review comments, lowercased and genericized: product names, internal paths and people are changed, and the reasoning and shape are kept. They show what he notices and how he reasons. When phrasing differs from the voice in `SKILL.md`, follow `SKILL.md`: Ian wants his reviewer voice more inquisitive than his natural habit (see "habit vs preferred" at the end).

## the right abstraction

> i think we actually need a separate enum for record-level capabilities, not `UserScopes`. i didn't realize when we first discussed this, but `UserScopes` is for user-level oauth2 scopes, not per-record permissions.

> why do we have 2 different variants of the same method? if multiple items can be output, the interface should always return an array. if i were working with this code i would have no idea which method to call

> actually, i guess my real question is why the theme needs a slug at all?

> hmm, why the extra `itemsToUpdate` property? couldn't this just take a `LineItem[]`?

> not entirely related to this pr, but the certificate should reflect the snapshot at issue time, not the current course. if i was issued one for an old version of the course, it wouldn't make sense to show the new one, since i didn't take that version

## re-implementing what exists

> i think this is re-implementing the `extractID` utility from `payload/shared`?

> a bit confused why we wouldn't just use a virtual field? this looks like a roundabout way of re-implementing `virtual: 'tenant.url'`, and it causes n+1 queries on listings: loading a list of 100 items would trigger 100 database round trips

> no need to implement this ourselves, we already depend on `jose`, which has `decodeJwt`

> can't all of this procedural parsing be replaced with a simple zod schema?

## where code belongs

> this module feels all over the place: it's in `components` but it's not jsx, and it has business logic that belongs in a service but returns a `Request`. imo it would make more sense in the feature's service, returning the domain object, with the `Request` part in the route handler. then both conversions are testable on their own

> is it really the image worker's job to handle relative urls? it has no idea what they're relative to.

> i don't think the table component should know or care about routing. the route handlers are where that logic belongs. having the route pass sort/filter/columns as props would simplify the component and make it obvious what each route does

> this seems like a good chance to not add to the already-bloated controller, given it's a pretty encapsulated feature

## coupling

> can we pass a bool `focus` instead? the individual row shouldn't really have to care about what its index is

> this is fragile and depends on implementation details of the storage plugin. any change to that plugin's config or internals will break this endpoint silently, especially with casts like `result.Body as AsyncIterable<Uint8Array>`

> why do we need a new pattern for this? there are existing rpc consumers, so we should be able to set up the client the same way

## dead code

> i'm very confused, what's the point of this? i can't find any usages of `existsConditions` anywhere. is that intentional?

> actually it looks like there's already a handler in `mocks/handlers.ts`, can this just be removed?

> i don't think this adr is really representative anymore, can we remove it?

> i like deleting code, lgtm

## simplest thing that works

> why a batch? 1 image per request is much simpler, and the status code clearly says success or failure

> i'm not clear why we need to chunk these, is there an issue with 1 query per insert? it's way more complex with batching, so i'd avoid it unless there's a clear reason

> good! this component is handling controlled/uncontrolled modes nicely :smile: we can simplify a bit more and drop `isControlled`: `controlledValue ?? uncontrolledValue`

## root cause over workaround

> i don't think faking their tenant assignments is the right solution. either this hack ends up everywhere or there will be places that silently fail

> i think globally disabling session refreshes has a disproportionate impact on the whole app. given this only happens inside the cms, could we try a fix localized to its auth adapter first?

## hidden cost

> i think this needs to be reworked. mirroring content across tenants makes cdn invalidations unfeasible: they're charged per path, so the cost doubles for every tenant we add

> how many records are we expecting to have? lazy-loading them in a loop will get quite slow if that number starts to get high

> do we have justification for these indices? gin indices have notable storage costs, so ideally we'd have `EXPLAIN ANALYZE` plans from before and after

> shouldn't this include `tenant`? this would return different results on 2 tenants but share a cache entry

> if these are all required they will break people's dev environments. they should either have sample values in `.env.example` or not be required in development

## observability and safe rollouts

> is this error logging really useful if we don't include the document id so it can be traced back to the record?

> would we not want to error log on all statuses for debugging purposes?

> i would think we want to send the user's id so we can associate it back. debugging from the function logs will be very difficult otherwise

> why not just throw (which the error tracker already catches) or error log? building on the tracker's sdk directly locks us into its api and is useless for local dev

> i don't think we need cms schema and ui for this setting, it'll likely be toggled rarely or never. i'd suggest a feature flag bound to a runtime parameter that defaults to enabled, so if we ever need to turn it off we can flip it from the console

## types

> in general, type assertions are a smell. this is a good example of why: if `jwtPayload` isn't set, `payload.sub` throws, and typescript would normally catch that, but the cast is hiding it

> since this is a mapper, i'd suggest an explicit return type so it's clearly a mapping from input type to output type, ideally using the generated types

## tests as the spec

> i see you've added assertions to other test cases to cover the different capability scenarios. i'd rather see all of them in this test case, so it's a single reference point for what the expected behavior is:
>
> 1. create a record
> 2. a user with edit permission and an admin get read, update and delete
> 3. a user without edit permission gets read only

## naming

> the filename and hook name don't match! nothing about this hook is infinite-scroll specific, so `useIntersectionObserver` sounds like a better name to me

> i think a more idiomatic name for this module would be `schemas`. i didn't expect to see zod schemas in here until reading through the file

## thinking out loud

> oh sorry, i just realized this is actually displaying a list...

> ah, actually it looks like that package doesn't have the same defaults as the cms one, which is why it may not have worked locally. never mind!

> do you recall why this was set to 9001? mine wasn't working on 9001, so i'm in favor of going back to 9000

> :grimacing: sending a redirect in a preprocess hook is... dangerous. this will redirect whenever the item is rendered as a teaser in a listing

> i definitely understand the need, but removing type linting makes me sad

## praise, approvals and blocking

> partial application, nice 👍

> lgtm, just needs a rebase

> looks good, thank you!

> as-is, this will likely fail if the user's token is near expiry on submit. confirmed that's an acceptable risk for now, so merging as-is

> all comments could be addressed in a follow-up pr if this needs to go out urgently

> the unique index is a blocking issue as it's destructive to existing data. the other 2 comments should be simple fixes but not blocking

## habit vs preferred

Ian's natural phrasing is sometimes sharper than he wants his reviewer voice to be. Keep the substance, use the inquisitive form:

| habit | preferred |
|---|---|
| lots of nasty typecasts here, why not use the utilities provided by payload? | could these use payload's utilities instead of the casts? i think they'd catch the shape mismatches the casts are hiding |
| need to fix the root cause | i don't think this fixes the root cause, could we look at why the tenant isn't assigned in the first place? |
| why not just use a `Set`? | would a `Set` be simpler here? |
| this logic is wrong | i think this is backwards: a certificate from an old version of the course would show the new image |
