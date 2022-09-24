async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    console.log("Account balance:", (await deployer.getBalance()).toString());

    const RepuFactory = await ethers.getContractFactory("RepuFactory");
    const repuFactory = await RepuFactory.deploy();

    console.log("RepuFactory address:", repuFactory.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });