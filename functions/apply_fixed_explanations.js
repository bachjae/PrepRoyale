const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin
const serviceAccountPath = path.join(__dirname, '../sat-act-battle-royale-firebase-adminsdk-fbsvc-eb52a46726.json');
const serviceAccount = require(serviceAccountPath);
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'sat-act-battle-royale',
});

const db = admin.firestore();

// Hardcoded array of the 18 specific fixes
const updates = [
  {
    id: "5nHTgU2Id0HQ9WFtPbcy",
    questionText: "The sum of two numbers is 20. The larger number is 4 less than twice the smaller number. What is the smaller number?",
    explanation: "Let x be the smaller number and y be the larger number. We are given the system of equations x + y = 20 and y = 2x - 4. Substituting the second equation into the first gives x + (2x - 4) = 20, which simplifies to 3x - 4 = 20. Solving for x yields 3x = 24, so x = 8. The smaller number is 8."
  },
  {
    id: "6ldZMgmyIheGcYBz8A9l",
    choices: ["5/2", "13/4", "2", "14/3"],
    explanation: "First, find the slope of line L1. The equation 2x + 3y = 6 can be rewritten in slope-intercept form as y = (-2/3)x + 2, meaning its slope is -2/3. Since L2 is perpendicular to L1, its slope is the negative reciprocal, which is 3/2. Using the point-slope form with the point (4, -1), the equation of L2 is y + 1 = (3/2)(x - 4). Simplifying this yields y = (3/2)x - 7. The point where L2 intersects the x-axis (the x-intercept) occurs when y = 0. Solving 0 = (3/2)x - 7 gives x = 14/3. The distance from the origin (0,0) to the point (14/3, 0) is simply 14/3."
  },
  {
    id: "7i2DGyQFOpUjqxMGHygc",
    choices: ["150", "160", "225", "200"],
    explanation: "To maximize the total number of widgets produced, the company should produce as many of the cheaper widgets (Type A) as possible while meeting the minimum requirements for both types. The cost equation is 5x + 8y = 1200, where x >= 50 and y >= 25. First, satisfy the minimum requirement for Type B widgets by producing exactly 25. This costs 8 * 25 = $200. The remaining budget is 1200 - 200 = $1000. Using this entire remaining budget on the cheaper Type A widgets yields 1000 / 5 = 200 Type A widgets. Adding the 25 Type B widgets, the maximum total number of widgets is 200 + 25 = 225."
  },
  {
    id: "FDCtUKKtKr7TAN49GU2j",
    correctAnswer: 2,
    explanation: "Let 'a' represent the number of apples and 'b' represent the number of bananas. We can create a system of two equations based on the quantities and total revenue: a + b = 200, and 1.50a + 0.75b = 225. From the first equation, we can isolate b: b = 200 - a. Substitute this into the second equation: 1.50a + 0.75(200 - a) = 225. Distributing the 0.75 yields 1.50a + 150 - 0.75a = 225. Combining like terms gives 0.75a = 75, which means a = 100. Therefore, 100 apples were sold."
  },
  {
    id: "FFdFnP5SOamGBL8JQVcU",
    choices: ["2/9", "1/4", "1/3", "1/2"],
    explanation: "First, determine the total number of equally likely outcomes where the sum of two six-sided dice is even. An even sum occurs when both dice are even or both are odd, resulting in 18 total possible outcomes (sums of 2, 4, 6, 8, 10, or 12). Next, identify the subset of these outcomes where the sum is strictly greater than 8. The only even sums greater than 8 are 10 and 12. There are 3 ways to roll a 10 (4+6, 5+5, 6+4) and 1 way to roll a 12 (6+6), totaling 4 favorable outcomes. The conditional probability is the number of favorable outcomes divided by the total number of condition-meeting outcomes: 4 / 18, which simplifies to 2/9."
  },
  {
    id: "MOCVdUVRnY2VbJyIyZDC",
    questionText: "A rectangular garden is 12 feet long and 8 feet wide. A path of uniform width is built around the garden. If the area of the path is 224 square feet, what is the width of the path, in feet?",
    explanation: "Let x be the uniform width of the path. The overall dimensions of the garden including the path become (12 + 2x) by (8 + 2x). The area of the path alone is the total area minus the area of the garden itself. The garden's area is 12 * 8 = 96 sq ft. Therefore, the area of the path is (12 + 2x)(8 + 2x) - 96. Setting this equal to the given path area of 224 sq ft, we get (12 + 2x)(8 + 2x) - 96 = 224, or (12 + 2x)(8 + 2x) = 320. Expanding the left side gives 4x² + 40x + 96 = 320, which simplifies to 4x² + 40x - 224 = 0. Dividing by 4 yields x² + 10x - 56 = 0. Factoring this quadratic gives (x + 14)(x - 4) = 0. Since width cannot be negative, x = 4. The width of the path is 4 feet."
  },
  {
    id: "MPhOoEHiGJmxbCuSXaVe",
    choices: ["1250 gallons", "1350 gallons", "1550 gallons", "1450 gallons"],
    explanation: "To find the total volume of water after one hour (60 minutes), calculate the water added during each interval and add it to the initial amount. The pool starts with 500 gallons. For the first 30 minutes, water is added at 20 gallons per minute, contributing 30 * 20 = 600 gallons. For the remaining 30 minutes, water is added at 15 gallons per minute, contributing 30 * 15 = 450 gallons. The total amount of water is the sum of these values: 500 + 600 + 450 = 1550 gallons."
  },
  {
    id: "ORUDqkfSbK0TFWhT6oix",
    correctAnswer: 2,
    explanation: "Since the graph passes through the given points, we can substitute them into the equation to create a system of two equations. Using the point (1, 2), substitute x=1 and y=2 to get 2 = 1² + b(1) + c, which simplifies to b + c = 1. Using the point (2, 5), substitute x=2 and y=5 to get 5 = 2² + b(2) + c, which simplifies to 2b + c = 1. Subtract the first equation from the second to eliminate c: (2b + c) - (b + c) = 1 - 1, which yields b = 0. Substitute b = 0 back into the first equation: 0 + c = 1. Therefore, c = 1."
  },
  {
    id: "OmnpUslGkYGIq1zauPkc",
    questionText: "The quadratic equation ax² + bx + c = 0 has solutions x = 1 and x = -2. If a - b + c = 4, what is the value of c?",
    explanation: "Since the quadratic equation has solutions x = 1 and x = -2, the equation must take the form k(x - 1)(x + 2) = 0 for some constant k. Expanding this expression yields k(x² + x - 2) = 0, or kx² + kx - 2k = 0. By matching coefficients with ax² + bx + c = 0, we determine that a = k, b = k, and c = -2k. We are given the condition a - b + c = 4. Substituting our terms for k yields k - k - 2k = 4, which simplifies to -2k = 4, giving k = -2. Since c = -2k, we find c = -2(-2) = 4."
  },
  {
    id: "QS5GSjgdh1famCnF8MIC",
    correctAnswer: 2,
    explanation: "To evaluate f(f(-3)), start from the innermost function. First, evaluate f(-3). Since -3 is less than 0, use the first piece of the piecewise function: f(-3) = -3 + 2 = -1. Next, substitute this result back into the function to evaluate f(-1). Because -1 is also less than 0, use the first piece again: f(-1) = -1 + 2 = 1. Therefore, f(f(-3)) = 1."
  },
  {
    id: "T7W05jCS99NW7ZqSOQJR",
    choices: ["-4", "-2.5", "2", "8"],
    correctAnswer: 1,
    explanation: "First, determine the linear equation for f(x). The slope of the line passing through (-1, 2) and (3, -4) is m = (-4 - 2) / (3 - (-1)) = -6 / 4 = -3/2. Using the point-slope form y - y₁ = m(x - x₁) with the point (-1, 2), we get f(x) - 2 = (-3/2)(x - (-1)). Simplifying this yields f(x) = (-3/2)x - 3/2 + 2 = (-3/2)x + 1/2. Next, we need to evaluate g(1). Based on the definition of g, g(1) = f(2 * 1) = f(2). Substitute x = 2 into our equation for f: f(2) = (-3/2)(2) + 1/2 = -3 + 0.5 = -2.5. Thus, g(1) = -2.5."
  },
  {
    id: "VxDUmaAHu1FfB79wKyxu",
    questionText: "A baker makes two types of cookies: chocolate chip and oatmeal raisin. A batch of chocolate chip cookies requires 3 cups of flour and 2 cups of sugar. A batch of oatmeal raisin cookies requires 4 cups of flour and 1 cup of sugar. The baker has 56 cups of flour and 24 cups of sugar. If the baker wants to use all of the flour and sugar, how many batches of chocolate chip cookies can the baker make?",
    explanation: "Let c represent the number of batches of chocolate chip cookies and o represent the number of batches of oatmeal raisin cookies. Based on the ingredients, we can set up a system of two equations: one for flour (3c + 4o = 56) and one for sugar (2c + o = 24). To solve for c, isolate o in the second equation: o = 24 - 2c. Substitute this expression into the first equation: 3c + 4(24 - 2c) = 56. Expanding this gives 3c + 96 - 8c = 56. Simplifying yields -5c = -40, so c = 8. The baker can make 8 batches of chocolate chip cookies."
  },
  {
    id: "ZwQXSIOhdIYyhEUveF1R",
    correctAnswer: 0,
    explanation: "By the properties of exponents, 2^(xy) is equivalent to (2^x)^y. We are given the equation 2^x = 3. Substituting 3 for 2^x in our expression gives (3)^y. The second given equation states that 3^y = 4. Therefore, by direct substitution, 2^(xy) = (2^x)^y = 3^y = 4."
  },
  {
    id: "b7doMhqy1h5509yReAe6",
    questionText: "A rectangular garden has a perimeter of 68 feet. If the length of the garden is decreased by 4 feet and the width is increased by 2 feet, the area of the garden remains the same. What is the original length of the garden?",
    explanation: "Let l be the original length and w be the original width of the rectangle. The perimeter is 68, meaning 2l + 2w = 68, which simplifies to l + w = 34. The area initially is lw. If the length is decreased by 4 (l - 4) and the width is increased by 2 (w + 2), the new area is equivalent to the original: (l - 4)(w + 2) = lw. Expanding the left side gives lw + 2l - 4w - 8 = lw. Subtracting lw from both sides yields 2l - 4w = 8, which simplifies to l - 2w = 4. Now we have a system of two equations: l + w = 34 and l - 2w = 4. From the first equation, w = 34 - l. Substituting this into the second equation gives l - 2(34 - l) = 4. Distributing solving yields l - 68 + 2l = 4, so 3l = 72, which means l = 24. The original length is 24 feet."
  },
  {
    id: "gUZTqhB3a5aGTcxJvOUn",
    questionText: "A system of equations is given by: ax + by = 7 and cx + dy = 10. If the solution to the system is x = 1 and y = 2, what is the value of a + 2b + c + 2d?",
    explanation: "Since the solution to the system of equations is x = 1 and y = 2, we can substitute these values directly into both equations to get a(1) + b(2) = 7, which is a + 2b = 7, and c(1) + d(2) = 10, which is c + 2d = 10. The expression we need to evaluate is a + 2b + c + 2d. By grouping the terms, we can see this is exactly the sum of the left sides of our two substituted equations: (a + 2b) + (c + 2d). Therefore, substituting our known values, the sum is 7 + 10 = 17."
  },
  {
    id: "hHfpC3XRojjqUhGePKb7",
    choices: ["(0, 2)", "(1, 3)", "(2, 5)", "(3, 0)"],
    correctAnswer: 0,
    explanation: "To find a point that is a solution to the system of inequalities, we must find a coordinate pair (x, y) that makes both inequalities true. Let's test the correct point (0, 2). Substituting x = 0 and y = 2 into the first inequality gives 2 > 2(0) + 1, which simplifies to 2 > 1. This is a true statement. Next, substituting into the second inequality gives 2 < -(0) + 4, which simplifies to 2 < 4. This is also a true statement. Since (0, 2) satisfies both conditions, it is a valid solution to the system."
  },
  {
    id: "ntSkPgXiyPwlJhJOZcjg",
    questionText: "The function f is defined as f(x) = 2x + k, where k is a constant. If f(f(1)) = 16, what is the value of k?",
    explanation: "First, evaluate the inner function f(1) by substituting x = 1 into the function definition: f(1) = 2(1) + k = 2 + k. Next, evaluate the outer function by substituting the expression (2 + k) back into the function: f(f(1)) = f(2 + k) = 2(2 + k) + k. Distributing the 2 gives 4 + 2k + k, which simplifies to 4 + 3k. We are given the condition that f(f(1)) = 16. Setting our derived expression equal to 16 yields 4 + 3k = 16. Subtracting 4 from both sides leaves 3k = 12, so k = 4."
  },
  {
    id: "omqCIbjKChTuRRt80uj5",
    questionText: "Company A sells widgets for $12 each and has fixed costs of $5000 per month. Company B sells the same widgets for $15 each but has fixed costs of $8000 per month. How many widgets must each company sell in a month for their total profit (revenue minus fixed costs) to be equal?",
    correctAnswer: 0,
    explanation: "The profit for a company is defined as its total revenue minus its costs. Since there are no variable production costs given, the profit for Company A is the revenue per widget times the number of widgets minus the monthly fixed costs: P_A = 12w - 5000. Similarly, the profit for Company B is P_B = 15w - 8000. To find the point where their profits are equal, set the two expressions equal to each other: 12w - 5000 = 15w - 8000. Subtract 12w from both sides to get -5000 = 3w - 8000. Add 8000 to both sides to get 3000 = 3w. Dividing by 3 yields w = 1000. Each company must sell 1000 widgets to have equal net profits."
  }
];

async function applyFixes() {
  console.log('Starting Update...');
  let fixedCount = 0;

  for (const update of updates) {
    const docId = update.id;
    const docRef = db.collection('questions').doc(docId);
    
    // Remove id from the update payload
    const payload = { ...update };
    delete payload.id;
    
    await docRef.update(payload);
    console.log(`Successfully updated QA ${docId}`);
    fixedCount++;
  }
  
  console.log(`Finished fixing ${fixedCount} questions!`);
  process.exit(0);
}

applyFixes().catch(console.error);
