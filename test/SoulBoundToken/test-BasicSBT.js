// The following are tests for the basic soulbound token functionality.

const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('BasicSBT', function () {

  before(async () => {
    [owner, user1, user2, user3] = await ethers.getSigners();
    const SBTContract = await ethers.getContractFactory('BasicSBT');
    sbt = await SBTContract.deploy('Test SBT Token', 'SBT');
  });

  it('Should return the name and symbol', async function () {
    expect(await sbt.name()).to.equal('Test SBT Token');
    expect(await sbt.symbol()).to.equal('SBT');
  });

  it('hasSoul should return false for new query', async function () {
    expect(await sbt.hasSoul(user1.address)).to.equal(false);
  });

  it('Should mint a new soul', async function () {
    const soul = ['SpartanLabs', 'https://spartanlabs.studio/'];
    await sbt.mint(user1.address, soul);
  });

  it('hasSoul should return true', async function () {
    expect(await sbt.hasSoul(user1.address)).to.equal(true);
  });

  it('getSoul should return the correct identifier', async function () {
    const soul = await sbt.getSBTData(user1.address);
    //console.log(soul);
    expect(soul[0]).to.equal('SpartanLabs');
    expect(soul[1]).to.equal('https://spartanlabs.studio/');
  });

  it('validateAttribute should return true', async function () {
    const expectedSoul = ['SpartanLabs', 'https://spartanlabs.studio/'];
    expect(await sbt.validateAttribute(user1.address, expectedSoul)).to.equal(true);
  });

  it('validateAttribute should return false', async function () {
    const expectedSoul = ['SpartanLabss1', 'https://spartanlabs.studio/'];
    expect(await sbt.validateAttribute(user1.address, expectedSoul)).to.equal(false);
  });

  it('User should not be able to update soul', async function () {
    const soul = ['Spartan', 'https://www.spartangroup.io/team.html'];
    await expect(sbt.connect(user1).updateSBT(user1.address, soul)).to.be.revertedWith('Ownable: caller is not the owner');
  });

  it('getSoul should return the correct identifier after User attempted update', async function () {
    const soul = await sbt.getSBTData(user1.address);
    //console.log(soul);
    expect(soul[0]).to.equal('SpartanLabs');
    expect(soul[1]).to.equal('https://spartanlabs.studio/');
  });

  it('Owner should be able to update soul', async function () {
    const soul = ['Spartan', 'https://www.spartangroup.io/team.html'];
    await sbt.updateSBT(user1.address, soul);
  });

  it('getSoul should return the updated value', async function () {
    const soul = await sbt.getSBTData(user1.address);
    //console.log(soul);
    expect(soul[0]).to.equal('Spartan');
    expect(soul[1]).to.equal('https://www.spartangroup.io/team.html');
  });

  it('validateAttribute should return true after update', async function () {
    const expectedSoul = ['Spartan', 'https://www.spartangroup.io/team.html'];
    expect(await sbt.validateAttribute(user1.address, expectedSoul)).to.equal(true);
  });

  it('User should not be able to delete their data', async function () {
    await expect(sbt.connect(user1).burn(user1.address)).to.be.revertedWith('Ownable: caller is not the owner');
    expect(await sbt.hasSoul(user1.address)).to.equal(true);

  });

  it('Owner should be able to delete their data', async function () {
    await sbt.connect(owner).burn(user1.address);
  });

  it('hasSoul should return false after delete', async function () {
    expect(await sbt.hasSoul(user1.address)).to.equal(false);
  });

  it('Should mint another soul for user2', async function () {
    const soul = ['Alice Smith', 'https://github.com'];
    await sbt.mint(user2.address, soul);
    // check that user2 has a soul
    expect(await sbt.hasSoul(user2.address)).to.equal(true);
  });

});