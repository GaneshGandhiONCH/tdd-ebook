# Where are objects composed?

Ok, we went through some ways of passing a recipient to a sender. We did it from the "internal" perspective of a sender that is given a recipient. What we left out for the most part is the "external" perspective, i.e. who should pass the recipient into the sender?

For almost all of the approaches described above there is no limitation -- you pass the recipient from where you need to pass it.

There is one approach, however, that is more limited, and this approach is **passing as a constructor parameter**.

Why is that? Because, we are trying to be true to the principle of "separating objects creation from use" and this, in turn, is a result of us striving for composability.

Anyway, if an object cannot both use and create another object, we have to make special objects just for creating other objects (there are some design patterns for how to design such objects, but the most popular and useful is a **factory**) or defer the creation up to the application entry point (there is also a pattern for this, called **composition root**).

So, we have two cases to consider. I'll start with the second one - composition root.

## Composition Root

let's assume, just for fun, that we are creating a mobile game where a player has to defend a castle. This game has two levels. Each level has a castle to defend. When we manage to defend the castle long enough, the level is considered completed and we move to the next one. So, we can break down the domain logic into three classes: a `Game` that has two `Level`s and each of them that contain a `Castle`. Let's also assume that the first two classes violate the principle of separating use from construction, i.e. that a `Game` creates its own levels and each `Level` creates its own castle.

A `Game` class is created in the `Main()` method of the application:

```csharp
public static void Main(string[] args)
{
  var game = new Game();

  game.Play();
}
```

The `Game` creates its own `Level` objects of specific classes implementing the `Level` interface and stores them in an array:

```csharp
public class Game
{
  private Level[] _levels = new[] {
    new Level1(), new Level2()
  };

  //some methods here that use the levels
}
```

And the `Level` implementations create their own castles and assign them to fields of interface type `Castle`:

```csharp
public class Level1
{
  private Castle _castle = new SmallCastle();

  //some methods here that use the castle
}

public class Level2
{
  private Castle _castle = new BigCastle();

  //some methods here that use the castle
}
```

Now, I said (and I hope you see it in the code above) that the `Game`, `Level1` and `Level2` classes violate the principle of separating use from construction. We don't like this, do we? Let's try to make them more compliant to the principle.

### Achieving separation of use from construction

TODO

First, let's refactor the `Level1` and `Level2` according to the principle by moving instantiation of their castles outside. As existence of a castle is required for a level to make sense at all -- we will say this in code by using the approach of passing a castle through a `Level`'s constructor:

```csharp
public class Level1
{
  private Castle _castle;
  
  //now castle is received as
  //constructor parameter
  public Level1(Castle castle)
  {
    _castle = castle;
  }
  
  //some methods here that use the castle
}

public class Level2
{
  private Castle _castle;
  
  //now castle is received as
  //constructor parameter
  public Level2(Castle castle)
  {
    _castle = castle;
  }
  
  //some methods here that use the castle
}
```

This was easy, wasn't it? The only problem is that if the instantiations of castles are not in `Level1` and `Level2` anymore, then they have to be passed by whoever creates the levels. In our case, this falls on the shoulders of `Game` class:
 
```csharp
public class Game
{
  private Level[] _levels = new[] {
    //now castles are created here as well: 
    new Level1(new SmallCastle()), 
    new Level2(new BigCastle())
  };
  
  //some methods here that use the levels
}
```

But remember -- this class suffers from the same violation of not separating objects use from construction as the levels did. Thus, to make this class compliant to the principle as well, we have to do the same to it that we did to the level classes -- move the creation of levels out of it:

```csharp
public class Game
{
  private Level[] _levels;
  
  //now levels are received as 
  //constructor parameter
  public Game(Level[] levels)
  {
    _levels = levels;
  }
  
  //some methods here that use the levels
}
```

There, we did it, but again, the levels now must be supplied by whoever creates the `Game`. Where do we put them? In our case, the only choice left is the `Main()` method of our application, so this is exactly what we are going to do:

```csharp
public static void Main(string[] args)
{
  var game = 
    new Game(
      new Level[] { 
        new Level1(new SmallCastle()), 
        new Level2(new BigCastle())
  });
  
  game.Play();
}
```

By the way, the `Level1` and `Level2` are differed only by the castle types and this difference is no more as we refactored it out, so we can make them a single class and call it e.g. `TimeSurvivalLevel` (because such level is considered completed when we manage to defend our castle for a specific period of time). After this move, now we have:

```csharp
public static void Main(string[] args)
{
  var game = 
    new Game(
      new Level[] { 
        new TimeSurvivalLevel(new SmallCastle()), 
        new TimeSurvivalLevel(new BigCastle())
  });
  
  game.Play();
}
```

Looking at the code above, we might come to another funny conclusion -- this violates the principle of separating use from construction as well! First, we create and connect the web of objects and then send the `Play()` message to the `game` object. Shouldn't we fix this as well? 

The answer is "no", for two reasons:

 1. There is no further place we can defer the creation. Sure, we could move the creation of the `Game` object and its dependencies into a separate object responsible only for the creation (we call such object **a factory**, as you already know), but it's a dead end, because it would leave us with the question: where do we create the factory?
 2. The whole point of the principle we are trying to apply is decoupling, i.e. giving ourselves the ability to change one thing without having to change another. When we think of it, there is no point of decoupling the entry point of the application from the application itself, since this is the most application-specific and non-reusable part of the application we can imagine.

What is important is that we reached a place where the web of objects is created using constructor approach and we have no place left to defer the creation of the web (in other words, it is as close as possible to application entry point). Such a place is called [**a composition root**](http://blog.ploeh.dk/2011/07/28/CompositionRoot/).

We say that composition root is "as close as possible" to application entry point, because there may be different frameworks in control of your application and you will not always have the `Main()` method at your service[^seemanndi].

Apart from the constructor invocations, the composition root may also contain, e.g., registrations of observers (see registration approach to passing recipients) if such observers are already known at this point. It is also responsible for disposing of all objects it created that require explicit disposal after the application finishes running. This is because it creates them and thus it is the only place in the code that can safely determine when they are not needed.

The composition root above looks quite small, but you can imagine it growing a lot in bigger applications. There are techniques of refactoring the composition root to make it more readable and cleaner -- we will explore such techniques in a dedicated chapter.

## Factories 

As I previously said, it is not always possible to pass everything through the constructor. One of the approaches we discussed that we can use in such cases is **a factory**.

When we previously talked about factories, we focused on it being just a source of objects. This time we will have a much closer look at what factory is and what are its benefits.

But first, let's look at an example of a factory emerging in code that was not using it, as a mere consequence of trying to follow the principle of separating objects use from construction.

### Emerging factory -- example  

Consider the following code that receives a frame from the network (as raw data), then packs it into an object, validates and applies to the system:
 
```csharp
public class MessageInbound
{
  //...initialization code here...
  
  public void Handle(Frame frame)
  {
    // determine the type of message
    // and wrap it with an object
    ChangeMessage change = null;
    if(frame.Type == FrameTypes.Update)
    {
      change = new UpdateRequest(frame);
    }
    else if(frame.Type == FrameTypes.Insert)
    {
      change = new InsertRequest(frame);
    }  
    else
    {
      throw 
        new InvalidRequestException(frame.Type);
    }
    
    change.ValidateUsing(_validationRules);
    _system.Apply(change);
  }
}
```

Note that this code violates the principle of separating use from construction. The `change` is first created, depending on the frame type, and then used (validated and applied) in the same method. On the other hand, if we wanted to separate the construction of `change` from its use, we have to note that it is impossible to pass an instance of the `ChangeMessage` through the `MessageInbound` constructor, because this would require us to create the `ChangeMessage` before we create the `MessageInbound`. Achieving this is impossible, because we can create messages only as soon as we know the frame data which the `MessageInbound` receives.

Thus, our choice is to make a special object that we would move the creation of new messages into. It would produce the new instances when requested, hence the name **factory**. The factory itself can be passed through constructor, since it does not require a frame to exist -- it only needs one when it is asked to create a message.

Knowing this, we can refactor the above code to the following:

```csharp
public class MessageInbound
{
  private readonly 
    MessageFactory _messageFactory;
  private readonly 
    ValidationRules _validationRules;
  private readonly 
    ProcessingSystem _system;
  
  public MessageInbound(
    //this is the factory:
    MessageFactory messageFactory,
    ValidationRules validationRules,
    ProcessingSystem system)
  {
    _messageFactory = messageFactory;
    _validationRules = validationRules;
    _system = system;
  }
  
  public void Handle(Frame frame)
  {
    var change = _messageFactory.CreateFrom(frame);  
    change.ValidateUsing(_validationRules);
    _system.Apply(change);
  }
}
```

This way we have separated message construction from its use. 

By the way, the factory itself looks like this:

```csharp
public class InboundMessageFactory
 : MessageFactory
{
  ChangeMessage CreateFrom(Frame frame)
  {
    if(frame.Type == FrameTypes.Update)
    {
      return new UpdateRequest(frame);
    }
    else if(frame.Type == FrameTypes.Insert)
    {
      return new InsertRequest(frame);
    }    
    else
    {
      throw 
        new InvalidRequestException(frame.Type);
    }
  }
}
```

And this is it. We have a factory now and the way we got to this point is by trying to be true to the principle of separating use from construction.

Now that we are through with the example, we are ready for some more general explanation on factories.

### Reasons to use factories

As you saw in the example, factories are objects responsible for creating other objects. They are used to achieve the separation of object constructions from their use when not all of the context necessary to create an object is known up-front. We pass the part of the context we know up-front (so called **global context**) in the factory via its constructor and supply the rest that becomes available later (so called **local context**) in a form of factory method parameters when it becomes available:

```csharp
var factory = new Factory(globalContextKnownUpFront);

//...

factory.CreateInstance(localContext);
```

Another case for using a factory is when we need to create a new object each time some kind of request is made (a message is received from the network or someone clicks a button):

```csharp
var factory = new Factory(globalContext);

//...

//we need a fresh instance
factory.CreateInstance();

//...

//we need another fresh instance
factory.CreateInstance();
```

In the above example, two independent instances are created, even though both are created in an identical way (there is no local context that would differ them).
 
Both these reasons were present in our example:

1. We were unable to create a `ChangeMessage` before knowing the actual `Frame`.
1. For each `Frame` received, we needed to create a new `ChangeMessage` instance. 

### Simplest factory

The simplest possible example of a factory object is something along the following lines:

```csharp
public class MyMessageFactory
{
  public MyMessage CreateMyMessage()
  {
    return new MyMessage();
  }
}
```

Even in this primitive shape the factory already has some value (e.g. we can make `MyMessage` an abstract type and return instances of its subclasses from the factory, and the only place impacted by the change is the factory itself[^essentialskills]). More often, however, when talking about simple factories, we think about something like this:

```csharp
//Let's assume MessageFactory 
//and Message are interfaces
public class XmlMessageFactory : MessageFactory
{
  public Message CreateSessionInitialization()
  {
    return new XmlSessionInitialization();
  }
}
```

Note the two things that the factory in the second example has that the one in the first example does not:

* it implements an interface (a level of indirection is introduced)
* its `CreateSessionInitialization()` method declares a return type to be an interface (another level of indirection is introduced)

In order for you to use factories effectively, I need you to understand why and how these levels of indirection are useful, especially when I talk with people, they often do not understand the benefits of using factories, "because we already have the `new` operator to create objects". So, here are these benefits:

### Factories allow creating objects polymorphically (encapsulation of type)

Each time we invoke a `new` operator, we have to put a name of a concrete type next to it:

```csharp
new List<int>(); //OK!
new IList<int>(); //won't compile...
```

This means that whenver we want to use the class that does this instantiation with another concrete object (e.g. a sorted list), we have to either change the code to delete the old type name and put new type name, or provide some kind of conditional (`if-else`). 

Factories do not have this defficiency. Because we get objects from factories by invoking a method, not by saying explicitly which class we want to get instantiated, we can take advantage of polymorphism, i.e. our factory may have a method like this:

```csharp
IList<int> CreateContainerForData() {...}
```

which returns any instance of a real class that implements `IList<int>` (say, `List<int>`):

```csharp
public IList<int> /* return type is interface */ 
CreateContainerForData() 
{
  return new List<int>(); /* instance of concrete class */
}
```

Of course, it makes little sense for the return type of the factory to be a library class or interface like in the above example (rather, we use factories to create instances of our own classes), but you get the idea, right? 

Anyway, it is typical for a return type of a factory to be an interface or, at worst, an abstract class. This means that whoever uses the factory, it knows only that it receives an object of a class that is implementing an interface or is derived from abstract class. But it does not know exactly what *concrete* type it is. Thus, a factory may return objects of different types at different times, depending on some rules only it knows.

Time to look at some more realistic example of how to apply this. Let's say we have a factory of messages like this:

```csharp
public class Version1ProtocolMessageFactory 
  : MessageFactory
{
  public Message NewInstanceFrom(MessageData rawData)
  {
    switch(rawData.MessageType)
    {
      case Messages.SessionInit:
        return new SessionInit(rawData);
      case Messages.SessionEnd:
        return new SessionEnd(rawData);
      case Messages.SessionPayload:
        return new SessionPayload(rawData);
      default:
        throw new UnknownMessageException(rawData);
    }
  }
}
```

The factory can create many different types of messages depending on what is inside the raw data, but from the perspective of the user of the factory, this is irrelevant. All that it knows is that it gets a `Message`, thus, it (and the rest of the code operating on messages in the whole application for that matter) can be written as general-purpose logic, containing no "special cases" dependent on type of message:

```csharp
var message = _messageFactory.NewInstanceFrom(rawData);
message.ValidateUsing(_primitiveValidations);
message.ApplyTo(_sessions);
```

Note that the above code does not need to change in case we want to add a new type of message that is compatible with the existing flow of processing messages[^messageotherchangecase]. The only place we need to modify in such case is the factory. For example, imagine we decided to add a session refresh message. The modified factory would look like this: 

```csharp
public class Version1ProtocolMessageFactory
  : MessageFactory
{
  public Message NewInstanceFrom(MessageData rawData)
  {
    switch(rawData.MessageType)
    {
      case Messages.SessionInit:
        return new SessionInit(rawData);
      case Messages.SessionEnd:
        return new SessionEnd(rawData);
      case Messages.SessionPayload:
        return new SessionPayload(rawData);
      case Messages.SessionRefresh: //new message type!
        return new SessionRefresh(rawData);
      default:
        throw new UnknownMessageException(rawData);
    }
  }
}
```

and the rest of the code could remain untouched.

Using the factory to hide the real type of message returned makes maintaining the code easier, because there is less code to change when adding new types of messages to the system or removing existing ones (in our example -- in case when we do not need to initiate a session anymore) [^encapsulatewhatvaries] -- the factory hides that and the rest of the application is coded against the general scenario.

The above example demonstrated how a factory can hide that many classes can play the same role (i.e. different messages could play the role of `Message`), but we can as well use factories to hide that the same class plays many roles. An object of the same class can be returned from different factory method, each time as a different interface and clients cannot access the methods it implements from other interfaces.

### Factories are themselves polymorphic (encapsulation of rule)

Another benefit of factories over inline constructors is that they are composable. This allows replacing the rule used to create objects with another one, by replacing one factory implementation with another.

In the example from the previous section, we examined a situation where we extended the existing factory with a `SessionRefresh` message. This was done with assumption that we do not need the previous version of the factory. But consider a situation where we need both versions of the behavior and want to be able to use the old version sometimes, and other times the new one. The "version 1" of the factory (the old one) would look like this:

```csharp
public class Version1ProtocolMessageFactory 
  : MessageFactory
{
  public Message NewInstanceFrom(MessageData rawData)
  {
    switch(rawData.MessageType)
    {
      case Messages.SessionInit:
        return new SessionInit(rawData);
      case Messages.SessionEnd:
        return new SessionEnd(rawData);
      case Messages.SessionPayload:
        return new SessionPayload(rawData);
      default:
        throw new UnknownMessageException(rawData);
    }
  }
}
```

and the "version 2" (the new one) would be:

```csharp
//note that now it is a version 2 protocol factory
public class Version2ProtocolMessageFactory
  : MessageFactory
{
  public Message NewInstanceFrom(MessageData rawData)
  {
    switch(rawData.MessageType)
    {
      case Messages.SessionInit:
        return new SessionInit(rawData);
      case Messages.SessionEnd:
        return new SessionEnd(rawData);
      case Messages.SessionPayload:
        return new SessionPayload(rawData);
      case Messages.SessionRefresh: //new message type!
        return new SessionRefresh(rawData);
      default:
        throw new UnknownMessageException(rawData);
    }
  }
}
```

Depending on what the user chooses in the configuration, we give them either a version 1 protocol support which does not support session refreshing, or a version 2 protocol support that does. Assuming the configuration is only read once during the application start, we may have the following code in our composition root:

```csharp
MessageFactory messageFactory = configuration.Version == 1 ?
  new Version1ProtocolMessageFactory() : 
  new Version2ProtocolMessageFactory() ;
  
var messageProcessing = new MessageProcessing(messageFactory);
```

The above code composes a `MessageProcessing` instance with either a `Version1ProtocolMessageFactory` or a `Version2ProtocolMessageFactory`, depending on the configuration. 

This example shows something I like calling "encapsulation of rule". The logic inside the factory is a rule on how, when and which objects to create. Thus, if we make our factory implement an interface and have other objects depend on this interface, we will be able to switch the rules of object creation without having to modify these objects.

### Factories can hide some of the created object dependencies (encapsulation of global context)

Let's consider another simple example. We have an application that, again, can process messages. One of the things that is done with those messages is saving them in a database and another is validation. The processing of message is, like in previous examples, handled by a `MessageProcessing` class, which, this time, does not use any factory, but creates the messages based on the frame data itself. Let's look at this class:

```csharp
public class MessageProcessing
{
  private DataDestination _database;
  private ValidationRules _validation;
  
  public MessageProcessing(
    DataDestination database,
    ValidationRules validation)
  {
    _database = database;
    _validation = validation;
  } 
  
  public void ApplyTo(MessageData data)
  {
    //note this creation:
    var message = 
      new Message(data, _database, _validation);
    
    message.Validate();
    message.Persist();
    
    //... other actions 
  }
}
```

There is one noticeable thing about the `MessageProcessing` class. It depends on both `DataDestination` and `ValidationRules` interfaces, but does not use them. The only thing it needs those interfaces for is to supply them as parameters to the constructor of a `Message`. As a number of `Message` constructor parameters grows, the `MessageProcessing` will have to change to take more parameters as well. Thus, the `MessageProcessing` class gets polluted by something that it does not directly need. 

We can remove these dependencies from `MessageProcessing` by introducing a factory that would take care of creating the messages in its stead. This way, we only need to pass `DataDestination` and `ValidationRules` to the factory, because `MessageProcessing` never needed them for any reason other than creating messages. This factory may look like this:

```csharp
public class MessageFactory
{
  private DataDestination _database;
  private ValidationRules _validation;
  
  public MessageFactory(
    DataDestination database,
    ValidationRules validation)
  {
    _database = database;
    _validation = validation;
  } 

  public Message CreateFrom(MessageData data)
  {
    return 
      new Message(data, _database, _validation);
  }
}
```

Now, note that the creation of messages was moved to the factory, along with the dependencies needed for this. The `MessageProcessing` does not need to take these dependencies anymore, and can stay more true to its real purpose:

```csharp
public class MessageProcessing
{
  private MessageFactory _factory;
  
  //now we depend on the factory only:
  public MessageProcessing(
    MessageFactory factory)
  {
    _factory = factory;
  } 
  
  public void ApplyTo(MessageData data)
  {
    //no need to pass database and validation
    //since they already are inside the factory:
    var message = _factory.CreateFrom(data);
    
    message.Validate();
    message.Persist();
    
    //... other actions 
  }
}
```

So, instead of `DataDestination` and `ValidationRules` interfaces, the `MessageProcessing` depends only on the factory. This may not sound as a very attractive tradeoff (taking away two dependencies and introducing one), but note that whenever the `MessageFactory` needs another dependency that is like the existing two, the factory is all that will need to change. The `MessageProcessing` will remain untouched and still coupled only to the factory.

The last thing that needs to be said is that not all dependencies can be hidden inside a factory. Note that the factory still needs to receive the `MessageData` from whoever is asking for a `Message`, because the `MessageData` is not available when the factory is created. You may remember that I call such dependencies a **local context** (because it is specific to a single use of a factory). On the other hand, what a factory accepts through its constructor can be called a **global context** (because it is the same throughout the factory lifetime). Using this terminology, the local context cannot be hidden from users of the factory, but the global context can. Thanks to this, the classes using the factory do not need to know about the global context and can stay cleaner, coupled to less things and more focused.

### Factories can help increase readability and reveal intention (encapsulation of terminology)

Let's assume we are writing an action-RPG game which consists of many game levels (not to be mistaken with experience levels). Players can start a new game or continue a saved game. When they choose to start a new game, they are immediately taken to the first level with empty inventory and no skills. Otherwise, when they choose to continue an old game, they have to select a file with a saved state (then the game level, skills and inventory are loaded from the file). Thus, we have two separate workflows in our game that end up with two different methods being invoked: `OnNewGame()` for new game mode and `OnContinue()` for resuming a saved game:

```csharp
public void OnNewGame()
{
  //...
}

public void OnContinue(PathToFile savedGameFilePath)
{
  //...
}

```

In each of these methods, we have to somehow assemble a `Game` class instance. The constructor of `Game` allows composing it with a starting level, character's inventory and a set of skills the character can use:

```csharp
public class FantasyGame : Game 
{
  public FantasyGame(
      Level startingLevel, 
      Inventory inventory, 
      Skills skills)
  {
  }
}
```

There is no special class for "new game" or for "resumed game" in our code. A new game is just a game starting from the first level with empty inventory and no skills:

```csharp
var newGame = new FantasyGame(
  new FirstLevel(), 
  new BackpackInventory(),
  new KnightSkills());
```

In other words, the "new game" concept is expressed by a composition of objects rather than by a single class, called e.g. `NewGame`. 

Likewise, when we want to create a game object representing resumed game, we do it like this:

```csharp
try
{
  saveFile.Open();
  
  var loadedGame = new FantasyGame(
    saveFile.LoadLevel(),
    saveFile.LoadInventory(),
    saveFile.LoadSkills());
}
finally
{  
  saveFile.Close();
}
```
Again, the concept of "resumed game" is represented by a composition rather than a single class, just like in case of "new game". On the other hand, the concepts of "new game" and "resumed game" are part of the domain, so we must make them explicit somehow or we loose readability.

One of the ways to do this is to use a factory[^simplerbutnotflexible]. We can create such factory and put inside two methods: one for creating a new game, another for creating a resumed game. The code of the factory could look like this:

```csharp
public class FantasyGameFactory : GameFactory
{
  public Game NewGame()
  {
    return new FantasyGame(
      new FirstLevel(), 
      new BackpackInventory(),
      new KnightSkills());
  }
  
  public Game GameSavedIn(PathToFile savedGameFilePath)
  {
    var saveFile = new SaveFile(savedGameFilePath); 
    try
    {
      saveFile.Open();
      
      var loadedGame = new FantasyGame(
        saveFile.LoadLevel(),
        saveFile.LoadInventory(),
        saveFile.LoadSkills());
      
      return loadedGame;
    }
    finally
    {
      saveFile.Close();
    }    
  }
}
``` 

Now we can use the factory in the place where we are notified of the user choice. Remember? This was the place:

```csharp
public void OnNewGame()
{
  //...
}

public void OnContinue(PathToFile savedGameFilePath)
{
  //...
}

```

When we fill the method bodies with the factory usage, the code ends up like this:

```csharp
public void OnNewGame()
{
  var game = _gameFactory.NewGame();
  game.Start();
}

public void OnContinue(PathToFile savedGameFilePath)
{
  var game = _gameFactory.GameSavedIn(savedGameFilePath);
  game.Start();
}

```
Note that using factory helps make the code more readable and intention-revealing. Instead of using a nameless set of connected objects, the two methods shown above ask using terminology from the domain (explicitly requesting either `NewGame()` or `GameSavedIn(path)`). Thus, the domain concepts of "new game" and "resumed game" become explicit. This justifies the first part of the name I gave this section (i.e. "Factories can help increase readability and reveal intention").

There is, however, the second part of the section name: "encapsulating terminology" which I need to explain. Here's an explanation: note that the factory is responsible for knowing what exactly the terms "new game" and "resumed game" mean. As the  meaning of the terms is encapsulated in the factory, we can change the meaning of these terms throughout the application merely by changing the code inside the factory. For example, we can say that new game starts with inventory that is not empty, but contains a basic sword and a shield, by changing the `NewGame()` method of the factory to this:

```csharp
  public Game NewGame()
  {
    return new FantasyGame(
      new FirstLevel(), 
      new BackpackInventory(
        new BasicSword(),
        new BasicShield()),
      new KnightSkills());
  }
```

Putting it all together, factories allow giving names to some specific object compositions to increase readability and introducing terminology that can be changed by changing code inside the factory methods.   

### Factories help eliminate redundancy

Redundancy in code means that at least two things need to change for the same reason in the same way[^essentialskills]. Usually it is understood as code duplication, but I consider "conceptual duplication" a better term. For example, the following two methods are not redundant, even though the code seems duplicated (by the way, the following is not an example of good code, just a simple illustration):

```csharp
public int MetersToCentimeters(int value)
{
  return value*100;
}

public int DollarsToCents(int value)
{
  return value*100;
}
```

As I said, this is not redundancy, because the two methods represent different concepts that would change for different reasons. Even if we were to extract "common logic" from the two methods, the only sensible name we could come up with would be something like `MultiplyBy100()` which wouldn't add any value at all.

Note that up to now, we considered four things factories encapsulate about creation of objects:

 1. Type
 2. Rule
 3. Global context
 4. Terminology

Thus, if factories didn't exist, all these concepts would leak to surrounding classes (we saw an example when we were talking about encapsulation of global context). Now, as soon as there is more than one class that needs to create instances, these things leak to all of these classes, creating redundancy. In such case, any change to how instances are created would mean a change to all classes needing those instances.

Thankfully, by having a factory -- an object that takes care of creating other objects and nothing else, we can reuse the ruleset, the global context and the type-related decisions across many classes without any unnecessary overhead. All we need to do is reference the factory and ask it for an object.

There are more benefits to factories, but I hope I already convinced you that this is a pretty darn beneficial concept for such a reasonably low cost.

## Summary


In this chapter, I tried to show you a variety of ways of composing objects together. Do not worry if you feel overwhelmed, for the most part, just remember to follow the principle of separating use from construction and you will be fine.

The rules outlined here apply to the overwhelming part of the objects in our application. Wait, did I say overwhelming? Not all? So there are exceptions? Yes, there are and we'll talk about them shortly, but first, we need to further examine the influence composability has on our object-oriented design approach.

[^encapsulatewhatvaries]: Note that this is an application of Gang of Four guideline: "encapsulate what varies".

[^seemanndi]: For details, check Dependency Injection in .NET by Mark Seemann.

[^essentialskills]: A. Shalloway et al., Essential Skills For The Agile Developer.

[^messageotherchangecase]: although it does need to change when the rule "first validate, then apply to sessions" changes

[^simplerbutnotflexible]: There are simple ways, yet none is as flexible as using factories.