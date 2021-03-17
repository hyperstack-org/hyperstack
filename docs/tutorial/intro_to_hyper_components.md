#Tutorial: Intro to React

This tutorial doesn’t assume any existing HyperStack or React knowledge.  

##Before We Start the Tutorial

> This tutorial is shamelessly stolen for pedagogical reasons from this [React tutorial](https://reactjs.org/tutorial/tutorial.html)

In this tutorial you will build a small game. Even though its just a small game, the techniques you’ll learn  are fundamental to building any HyperStack app, and mastering it will give you a deep understanding of not only Hyper Conponents but also of React.


> Tip: This tutorial is designed for people who prefer to learn by doing. If you prefer learning concepts from the ground up, check out our step-by-step guide. You might find this tutorial and the guide complementary to each other.

The tutorial is divided into several sections:

+ Setup for the Tutorial will give you a starting point to follow the tutorial.
+ Overview will teach you the fundamentals of HyperStack: Components, Params and State.
+ Completing the game will teach you the most common techniques in Hyperstack  development.
+ Adding Time Travel will give you a deeper insight into the unique strengths of HyperStack and the underlying React technologies.

You don’t have to complete all of the sections at once to get the value out of this tutorial. Try to get as far as you can — even if it’s one or two sections.

### What Are We Building?

In this tutorial, we’ll show how to build an interactive tic-tac-toe game with HyperStack.

###Prerequisites

We’ll assume that you have some familiarity with HTML and Ruby, but you should be able to follow along even if you’re coming from a different programming language such as Javascript, or if you have familiarit with React.  We’ll also assume that you’re familiar with programming concepts like methods (functions), objects, arrays, and to a lesser extent, classes.

Setup for the Tutorial
There are two ways to complete this tutorial: you can either write the code in your browser, or you can set up a local development environment on your computer.

Setup Option 1: Write Code in the Browser
This is the quickest way to get started!

First, open this Starter Code in a new tab. The new tab should display an empty tic-tac-toe game board and React code. We will be editing the React code in this tutorial.

You can now skip the second setup option, and go to the Overview section to get an overview of React.

Setup Option 2: Local Development Environment
This is completely optional and not required for this tutorial!


Optional: Instructions for following along locally using your preferred text editor
Help, I’m Stuck!
If you get stuck, check out the community support resources. In particular, Reactiflux Chat is a great way to get help quickly. If you don’t receive an answer, or if you remain stuck, please file an issue, and we’ll help you out.

Overview
Now that you’re set up, let’s get an overview of React!

What Is React?
React is a declarative, efficient, and flexible JavaScript library for building user interfaces. It lets you compose complex UIs from small and isolated pieces of code called “components”.

React has a few different kinds of components, but we’ll start with React.Component subclasses:

class ShoppingList extends React.Component {
  render() {
    return (
      <div className="shopping-list">
        <h1>Shopping List for {this.props.name}</h1>
        <ul>
          <li>Instagram</li>
          <li>WhatsApp</li>
          <li>Oculus</li>
        </ul>
      </div>
    );
  }
}

// Example usage: <ShoppingList name="Mark" />
We’ll get to the funny XML-like tags soon. We use components to tell React what we want to see on the screen. When our data changes, React will efficiently update and re-render our components.

Here, ShoppingList is a React component class, or React component type. A component takes in parameters, called props (short for “properties”), and returns a hierarchy of views to display via the render method.

The render method returns a description of what you want to see on the screen. React takes the description and displays the result. In particular, render returns a React element, which is a lightweight description of what to render. Most React developers use a special syntax called “JSX” which makes these structures easier to write. The <div /> syntax is transformed at build time to React.createElement('div'). The example above is equivalent to:

return React.createElement('div', {className: 'shopping-list'},
  React.createElement('h1', /* ... h1 children ... */),
  React.createElement('ul', /* ... ul children ... */)
);
See full expanded version.

If you’re curious, createElement() is described in more detail in the API reference, but we won’t be using it in this tutorial. Instead, we will keep using JSX.

JSX comes with the full power of JavaScript. You can put any JavaScript expressions within braces inside JSX. Each React element is a JavaScript object that you can store in a variable or pass around in your program.

The ShoppingList component above only renders built-in DOM components like <div /> and <li />. But you can compose and render custom React components too. For example, we can now refer to the whole shopping list by writing <ShoppingList />. Each React component is encapsulated and can operate independently; this allows you to build complex UIs from simple components.

Inspecting the Starter Code
If you’re going to work on the tutorial in your browser, open this code in a new tab: Starter Code. If you’re going to work on the tutorial locally, instead open src/index.js in your project folder (you have already touched this file during the setup).

This Starter Code is the base of what we’re building. We’ve provided the CSS styling so that you only need to focus on learning React and programming the tic-tac-toe game.

By inspecting the code, you’ll notice that we have three React components:

Square
Board
Game
The Square component renders a single <button> and the Board renders 9 squares. The Game component renders a board with placeholder values which we’ll modify later. There are currently no interactive components.

Passing Data Through Props
To get our feet wet, let’s try passing some data from our Board component to our Square component.

We strongly recommend typing code by hand as you’re working through the tutorial and not using copy/paste. This will help you develop muscle memory and a stronger understanding.

In Board’s renderSquare method, change the code to pass a prop called value to the Square:

class Board extends React.Component {
  renderSquare(i) {
    return <Square value={i} />;
  }
}
Change Square’s render method to show that value by replacing {/* TODO */} with {this.props.value}:

class Square extends React.Component {
  render() {
    return (
      <button className="square">
        {this.props.value}
      </button>
    );
  }
}
Before:

React Devtools
After: You should see a number in each square in the rendered output.

React Devtools
View the full code at this point
